-- Silence is a field over level cells. Player status, mutation aura,
-- monster enchantments, and Silent Spectres all contribute to one answer.
-- Source: areas.cc:silenced and both actor silence_radius methods.
local component = require("constants.component")
local monsters = require("ids.monsters")
local statuses = require("policy.magic.effects.statuses.player")

local silence = {}
local SPECTRE_RADIUS = 10
local BASELINE_AUT = 10
local MONSTER_MIN_MODIFIED_TURNS = 7
local MONSTER_STEP_SIZE = 10
local MONSTER_FIRST_STEP = 5
local MONSTER_STEP_CEILING = 100

-- Source shrinking_aoe_range uses the integer square root of a clamped
-- duration expression. A negative radius means no field at all.
local function shrinking_radius(duration_aut)
    if duration_aut <= 0 then
        return -1
    end

    local turns = math.floor(duration_aut / BASELINE_AUT)
    local square = math.max(0,
        math.min(math.floor(3 * (turns - 5) / 4), 25))

    return math.floor(math.sqrt(square))
end

-- Source stepdown_value is logarithmic above its first step. Monster
-- Silence uses this to keep a broad field until its final few turns.
local function monster_stepdown(value)
    if value < MONSTER_FIRST_STEP then
        return value
    end

    local offset = MONSTER_FIRST_STEP - MONSTER_STEP_SIZE
    local stepped = MONSTER_STEP_SIZE *
        math.log(1 + (value - offset) / MONSTER_STEP_SIZE) /
        math.log(2)

    return offset + math.min(MONSTER_STEP_CEILING - offset,
        math.floor(stepped))
end

-- A Silent Spectre has an innate field; enchanted monsters derive a
-- shrinking radius from their own remaining duration.
function silence.monster_radius(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)

    if actor and actor.kind_id == monsters.MONS_SILENT_SPECTRE then
        return SPECTRE_RADIUS
    end

    local state = ctx:get(monster, component.MONSTER_SILENCE)

    if not state or state.remaining_aut <= 0 then
        return -1
    end

    local modified = math.max(MONSTER_MIN_MODIFIED_TURNS,
        monster_stepdown(state.remaining_aut * 10 - 60))

    return shrinking_radius(BASELINE_AUT * modified)
end

-- An actor's own cell can be silenced by any source, including an enemy
-- monster whose aura overlaps the player or another monster.
function silence.at(ctx, level_id, x, y)
    local player = ctx:player()
    local player_pos = player and ctx:get(player, component.POSITION)
    local player_radius = player and
        statuses.silence_radius(ctx, player) or -1

    if player_pos and player_pos.level_id == level_id and
        player_radius >= 0 and
        math.max(math.abs(player_pos.x - x),
            math.abs(player_pos.y - y)) <= player_radius then
        return true
    end

    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if monster ~= player then
            local health = ctx:get(monster, component.HEALTH)

            if health.current > 0 then
                local site = ctx:get(monster, component.POSITION)
                local radius = silence.monster_radius(ctx, monster)

                if site.level_id == level_id and radius >= 0 and
                    math.max(math.abs(site.x - x),
                        math.abs(site.y - y)) <= radius then
                    return true
                end
            end
        end
    end

    return false
end

-- Callers with an actor handle use its indexed position, not an assumed
-- player position or stale coordinates captured before movement.
function silence.actor(ctx, actor)
    -- Self Silence does not require a grid lookup. This also lets command
    -- preflight work before a player position has been installed.
    if ctx:has(actor, component.PLAYER) and
        statuses.silence_radius(ctx, actor) >= 0 then
        return true
    end

    local position = ctx:get(actor, component.POSITION)

    return position ~= nil and silence.at(ctx,
        position.level_id, position.x, position.y)
end

-- The enchantment ages on its caster's actions and disappears at zero.
function silence.tick(ctx, monster, elapsed_aut)
    local state = ctx:get(monster, component.MONSTER_SILENCE)

    if not state then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 then
        ctx:remove(monster, component.MONSTER_SILENCE)
    else
        ctx:set(monster, component.MONSTER_SILENCE, state)
    end
end

return silence
