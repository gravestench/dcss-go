-- Example: A Felid revival spends one saved life and places the player on a safe floor.
-- Source: player.cc:will_gain_life and _felid_extra_life, ouch.cc:ouch.
local component = require("constants.component")
local terrain = require("constants.terrain")
local revivable = require("constants.revival_statuses")
local mutations = require("ids.mutations")
local catalog = require("policy.catalog")
local death = require("policy.death")
local experience_limit = require("policy.character.experience_limit")
local formulas = require("policy.character.formulas")
local targets = require("policy.ai.targets")
local levels = require("policy.mutations.levels")

local extra_lives = {}

-- Read the durable life ledger shared by death, advancement, and revival paths.
function extra_lives.state(ctx, player)
    return ctx:get(player, component.EXTRA_LIVES)
end

-- Check the effective Felid mutation before granting or spending lives.
function extra_lives.active(ctx, player)
    return levels.effective(ctx, player, mutations.MUT_MULTILIVED) > 0
end

-- Create a life ledger once; revisiting mutation transitions must not reset deaths.
function extra_lives.start(ctx, player)
    if not extra_lives.active(ctx, player) or
        extra_lives.state(ctx, player) then
        return
    end

    local progress = ctx:get(player, component.PROGRESSION)

    ctx:add(player, component.EXTRA_LIVES, {
        lives = 0,
        deaths = 0,
        max_level = progress and progress.level or 1,
        last_life_gained = 0,
        pending_revival = false,
    })
end

-- Felid life awards use historical level milestones, not just the current level after revival.
local function can_gain_life(state, level)
    if level < state.last_life_gained - 2 then
        return false
    end

    return state.lives + state.deaths <
        math.floor((level - 1) / 3)
end

-- Award milestones from newly attained levels while respecting the life-stock cap.
function extra_lives.on_level(ctx, player, level)
    if not extra_lives.active(ctx, player) then
        return
    end

    extra_lives.start(ctx, player)

    local state = extra_lives.state(ctx, player)

    state.max_level = math.max(state.max_level, level)

    if state.lives < 2 and can_gain_life(state, state.max_level) then
        state.lives = state.lives + 1
        state.last_life_gained = state.max_level
        ctx:emit("level-up", "Extra life!")
    end

    ctx:set(player, component.EXTRA_LIVES, state)
end

-- Source: player.cc:level_change keeps historical max XL growing after 27
-- so further XP thresholds can replace spent Felid lives.
function extra_lives.on_experience(ctx, player)
    local state = extra_lives.state(ctx, player)

    if not state or not extra_lives.active(ctx, player) then
        return
    end

    local progress = ctx:get(player, component.PROGRESSION)
    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)

    while state.max_level < 127 and progress.total_xp >=
        formulas.experience_needed(state.max_level + 1, species.xp) do
        extra_lives.on_level(ctx, player, state.max_level + 1)
        state = extra_lives.state(ctx, player)
    end
end

-- A Felid death spends a life and schedules revival; the actual relocation waits for the input boundary.
function extra_lives.on_lethal(ctx, player)
    local state = extra_lives.state(ctx, player)

    if not state or not extra_lives.active(ctx, player) or
        state.lives < 1 or state.pending_revival then
        return false
    end

    state.lives = state.lives - 1
    state.deaths = state.deaths + 1
    state.pending_revival = true
    ctx:set(player, component.EXTRA_LIVES, state)
    ctx:emit("death", "You die...")

    return true
end

-- Create or remove the ledger when the mutation changes, preserving valid existing state.
function extra_lives.changed(ctx, player)
    if extra_lives.active(ctx, player) then
        extra_lives.start(ctx, player)
    elseif extra_lives.state(ctx, player) then
        ctx:remove(player, component.EXTRA_LIVES)
    end
end

-- Score nearby actors at each candidate revival cell before choosing the safest sample.
local function threat(ctx, player, level_id, x, y)
    local general = 0
    local highest = 0

    for _, monster in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        local position = ctx:get(monster, component.POSITION)
        local health = ctx:get(monster, component.HEALTH)
        local distance = math.max(math.abs(position.x - x),
            math.abs(position.y - y))

        if monster ~= player and health.current > 0 and
            position.level_id == level_id and distance <= 7 and
            targets.enemy(ctx, monster, player) and
            ctx:visible(level_id, x, y, 7, position.x, position.y) then
            local actor = ctx:get(monster, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            local value = death.experience(definition, health.max)
            local weight = math.log(math.max(1, value))

            general = general + weight
            highest = math.max(highest, weight)
        end
    end

    return general * highest
end

-- Source: nearby-danger.cc:bring_to_safety samples at most 100 valid floor
-- cells and chooses the one with the lowest nearby hostile XP threat.
local function safe_position(ctx, player, position)
    local width, height = ctx:level_size(position.level_id)
    local best_x, best_y
    local best_threat = math.huge
    local valid = 0

    for _ = 1, 100000 do
        if valid >= 100 or best_threat == 0 then
            break
        end

        local x = ctx:random("revival", width)
        local y = ctx:random("revival", height)
        local occupant = ctx:actor_at(position.level_id, x, y)

        if ctx:cell(position.level_id, x, y) == terrain.DNGN_FLOOR and
            (not occupant or occupant == player) then
            valid = valid + 1

            local danger = threat(ctx, player, position.level_id, x, y)

            if danger < best_threat then
                best_threat = danger
                best_x = x
                best_y = y
            end
        end
    end

    return best_x, best_y
end

-- Preserve fractional XP progress within the old level when revival lowers the character.
local function lose_level(ctx, player)
    local progress = ctx:get(player, component.PROGRESSION)

    if not progress then
        return progress
    end

    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)
    local old_level = progress.level
    local maximum = experience_limit.max_level(ctx, player)

    if old_level <= 1 then
        progress.total_xp = 0
    elseif old_level - 1 >= maximum then
        progress.total_xp = formulas.experience_needed(maximum, species.xp)
    elseif progress.total_xp >=
        formulas.experience_needed(maximum, species.xp) then
        -- player.cc:adjust_level subtracts one capped-level interval before
        -- doing the fractional conversion. That consumes this level loss.
        progress.total_xp = progress.total_xp -
            formulas.experience_needed(maximum, species.xp) +
            formulas.experience_needed(maximum - 1, species.xp)
    else
        local old_min = formulas.experience_needed(old_level, species.xp)
        local old_max = formulas.experience_needed(old_level + 1, species.xp)
        local new_min = formulas.experience_needed(old_level - 1, species.xp)
        local new_max = old_min
        local earned = progress.total_xp - old_min

        progress.total_xp = new_min + math.floor(
            earned * (new_max - new_min) / (old_max - old_min))
    end

    progress.level = formulas.level_for_experience(
        progress.total_xp, species.xp, maximum)
    progress.pending_stat_level = 0
    ctx:set(player, component.PROGRESSION, progress)

    return progress
end

-- Revival removes lethal temporary states before the restored player can act.
local function clear_afflictions(ctx, player)
    for _, id in ipairs(revivable) do
        if ctx:has(player, id) then
            ctx:remove(player, id)
        end
    end

    for _, id in ipairs({ component.POISON, component.CONSTRICTION,
        component.PLAYER_CONSTRICTION }) do
        if ctx:has(player, id) then
            ctx:remove(player, id)
        end
    end

    if ctx:has(player, component.DURATIONS) then
        ctx:set(player, component.DURATIONS, {
            might_aut = 0,
            haste_aut = 0,
        })
    end
end

-- Recalculate HP and MP from the reduced level before ending the pending revival.
local function restore_vitals(ctx, player, level)
    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)
    local skills = ctx:get(player, component.SKILLS)
    local health = ctx:get(player, component.HEALTH)
    local magic = ctx:get(player, component.MAGIC)

    health.max = formulas.max_hp(ctx, player, level, species, skills.entries)
    health.current = health.max
    magic.max = formulas.max_mp(ctx, player, level, species, skills.entries)
    magic.current = magic.max
    ctx:set(player, component.HEALTH, health)
    ctx:set(player, component.MAGIC, magic)
end

-- Source: nearby-danger.cc:revive runs at the next input boundary, after
-- the fatal state has already been saved. Go only invokes this Lua policy.
function extra_lives.revive(ctx, player)
    local state = extra_lives.state(ctx, player)

    if not state or not state.pending_revival then
        return false
    end

    local position = ctx:get(player, component.POSITION)

    if not position then
        error("pending revival has no player position")
    end

    local progress = lose_level(ctx, player)

    clear_afflictions(ctx, player)
    restore_vitals(ctx, player, progress.level)

    local x, y = safe_position(ctx, player, position)

    if x then
        ctx:move_actor(player, position.level_id, x, y)
    end

    state.pending_revival = false
    state.last_life_gained = 0
    ctx:set(player, component.EXTRA_LIVES, state)
    ctx:emit("revival", "You rejoin the land of the living...")

    return true
end

-- Apply pending revival at the current-player input boundary and report whether it ran.
function extra_lives.revive_policy(ctx)
    return { revived = extra_lives.revive(ctx, ctx:player()) }
end

-- Check the life ledger against progression and health when restoring a saved player.
function extra_lives.validate(ctx, player, progress, health)
    local state = extra_lives.state(ctx, player)
    local active = extra_lives.active(ctx, player)

    if active and not state or state and not active then
        error("Multi-Lived mutation and extra-life state disagree")
    end

    if not state then
        return progress.level
    end

    local entitlement = math.floor((state.max_level - 1) / 3)

    if state.lives < 0 or state.lives > 2 or state.deaths < 0 or
        state.max_level < progress.level or state.max_level > 127 or
        state.last_life_gained < 0 or
        state.last_life_gained > state.max_level or
        state.lives + state.deaths > entitlement or
        state.pending_revival and health.current > 0 then
        error("invalid saved extra-life state")
    end

    return state.max_level
end

register.policy({
    id = "character.revive_pending",
    run = extra_lives.revive_policy,
})

return extra_lives
