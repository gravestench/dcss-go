local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local capabilities = require("constants.mutation_capabilities")
local flags = require("constants.monster_flags")
local habitats = require("constants.monster_habitats")
local holiness = require("constants.monster_holiness")
local channels = require("constants.message_channels")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local size = require("constants.size")
local confusion = require("policy.magic.player_confusion")
local forms = require("policy.magic.effects.forms.player")
local effects = require("policy.mutations.effects.registry")
local roll = require("policy.combat.roll")
local vision = require("policy.character.vision")
local monster_health = require("policy.combat.monster_health")

local engulf = {}

-- Treat absent catalog flags and holiness lists as empty when checking engulf immunity.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Water hold breaks across levels or when either actor moves beyond one tile.
local function adjacent(left, right)
    return left and right and left.level_id == right.level_id and
        math.abs(left.x - right.x) <= 1 and
        math.abs(left.y - right.y) <= 1 and
        (left.x ~= right.x or left.y ~= right.y)
end

-- Drowning and silence need the live monster species, so a missing actor is invalid state.
local function definition(ctx, target)
    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        error("engulf target has no monster actor")
    end

    return catalog.get(categories.MONSTERS, actor.kind_id), actor
end

-- Use transformed size when present, then fall back to the species body.
local function player_size(ctx, player)
    local choice = ctx:get(player, component.PLAYER)

    if not choice then
        error("engulf holder has no player choice")
    end

    local species = catalog.get(categories.SPECIES, choice.species_id)
    local body = catalog.get(categories.MONSTERS, species.monster_id)
    local form_size = forms.modifiers(ctx, player).size

    return size.rank[form_size] or size.rank[body.size_id]
end

-- The player must see and physically cover an adjacent nonspiny target before any RNG draw.
local function eligible(ctx, player, target, monster)
    local holder = ctx:get(player, component.POSITION)
    local victim = ctx:get(target, component.POSITION)

    if not adjacent(holder, victim) or
        confusion.active(ctx, player) or
        player_size(ctx, player) < size.rank[monster.size_id] or
        contains(monster.flags, flags.INSUBSTANTIAL) or
        contains(monster.flags, flags.SPINY) or
        monster.genus_id == monsters.MONS_JELLY then
        return false
    end

    return ctx:visible(holder.level_id, holder.x, holder.y,
        vision.radius(ctx, player), victim.x, victim.y)
end

-- Water dwellers and unliving creatures cannot be asphyxiated by an ooze hold.
local function breathes(monster)
    if monster.habitat_id == habitats.WATER or
        monster.habitat_id == habitats.AMPHIBIOUS then
        return false
    end

    return not contains(monster.holiness, holiness.UNDEAD) and
        not contains(monster.holiness, holiness.NONLIVING) and
        not contains(monster.holiness, holiness.PLANT)
end

-- Example: engulf.capability(level) with mutation level zero -> zero grip capacity
-- Convert mutation level to a constriction capacity shared by attack and maintenance checks.
function engulf.capability(level)
    return level > 0 and 1 or 0
end

-- A saved water-hold component is the single source of truth for an existing grab.
function engulf.active(ctx, target)
    return ctx:get(target, component.WATER_HOLD) ~= nil
end

-- Source: melee-attack.cc:do_ooze_engulf runs only after damage, then
-- actor.cc:can_engulf checks visibility, size, constriction resistance,
-- confusion, and adjacency before the final coin flip.
function engulf.on_player_hit(ctx, target, damage)
    local player = ctx:player()

    if damage <= 0 or engulf.active(ctx, target) or
        effects.sum(ctx, player, capabilities.ENGULF_ON_HIT) == 0 then
        return false
    end

    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 then
        return false
    end

    local monster = definition(ctx, target)

    if not eligible(ctx, player, target, monster) or
        ctx:random("mutation", 2) ~= 0 then
        return false
    end

    ctx:add(target, component.WATER_HOLD, {
        by = player,
        elapsed_aut = 1,
    })
    ctx:emit(channels.COMBAT,
        "You engulf the " .. monster.name .. " in ooze!")

    return true
end

-- Movement cancels the hold before later silence or drowning effects run.
function engulf.release_far(ctx, target)
    local state = ctx:get(target, component.WATER_HOLD)

    if not state then
        return false
    end

    local holder = ctx:get(state.by, component.POSITION)
    local victim = ctx:get(target, component.POSITION)

    if adjacent(holder, victim) then
        return false
    end

    ctx:remove(target, component.WATER_HOLD)

    return true
end

-- Sweep every held target after movement so stale distant holds do not linger.
function engulf.release_far_all(ctx)
    for _, target in ipairs(ctx:query({ component.WATER_HOLD })) do
        engulf.release_far(ctx, target)
    end
end

-- Only an adjacent hold on a breathing victim suppresses its spellcasting.
function engulf.silenced(ctx, target)
    local state = ctx:get(target, component.WATER_HOLD)

    if not state then
        return false
    end

    local holder = ctx:get(state.by, component.POSITION)
    local victim = ctx:get(target, component.POSITION)

    if not adjacent(holder, victim) then
        return false
    end

    return breathes(definition(ctx, target))
end

-- Source: mon-ench.cc increments the hold duration by one monster action
-- and applies random-rounded drowning damage to breathing targets.
function engulf.tick(ctx, target)
    if engulf.release_far(ctx, target) then
        return 0
    end

    local state = ctx:get(target, component.WATER_HOLD)

    if not state then
        return 0
    end

    local monster, actor = definition(ctx, target)

    if not breathes(monster) then
        return 0
    end

    local speed = actor.speed

    if speed < 1 then
        speed = 10
    end

    local duration = roll.random_divide(ctx, 100,
        math.min(speed, 100))

    state.elapsed_aut = state.elapsed_aut + duration
    ctx:set(target, component.WATER_HOLD, state)

    local stepdown = 30 * math.log(1 + state.elapsed_aut / 30) /
        math.log(2)
    local numerator = math.floor((50 + stepdown) * duration)
    local damage = roll.random_divide(ctx, numerator, 100)

    if damage <= 0 then
        return 0
    end

    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 then
        return 0
    end

    health = monster_health.damage(ctx, target, damage, ctx:player())
    ctx:emit(channels.COMBAT,
        "The " .. monster.name .. " is asphyxiated!")

    if health.current == 0 then
        ctx:signal("player_kill", target)
    end

    return damage
end

effects.add(mutations.MUT_ENGULF, {
    [capabilities.ENGULF_ON_HIT] = engulf.capability,
})

return engulf
