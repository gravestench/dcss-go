local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local capabilities = require("constants.mutation_capabilities")
local habitats = require("constants.monster_habitats")
local holiness = require("constants.monster_holiness")
local channels = require("constants.message_channels")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")
local roll = require("policy.combat.roll")
local monster_health = require("policy.combat.monster_health")
local substances = require("constants.water_hold_substances")
local player_health = require("policy.combat.player_health")
local eligibility = require("policy.combat.grip_eligibility")
local drowning = require("policy.combat.monster_beams.water")
local causes = require("constants.damage_causes")
local targets = require("policy.ai.targets")

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

    if not eligibility.can_engulf(ctx, player, target) or
        ctx:random("mutation", 2) ~= 0 then
        return false
    end

    ctx:add(target, component.WATER_HOLD, {
        by = player,
        elapsed_aut = 1,
        substance_id = substances.OOZE,
    })

    if ctx:has(target, component.STICKY_FLAME) then
        ctx:remove(target, component.STICKY_FLAME)
    end
    ctx:emit(channels.COMBAT,
        "You engulf the " .. monster.name .. " in ooze!")

    return true
end

-- A monster's AF_ENGULF uses the same saved status as the player's ooze
-- mutation. Keep the hit-time substance because a later polymorph must
-- not rewrite the text or identity of the original hold.
function engulf.on_monster_hit(ctx, hit)
    if engulf.active(ctx, hit.defender) then
        return false
    end

    local actor = ctx:get(hit.attacker, component.ACTOR)
    local watery = actor.kind_id ~= monsters.MONS_QUICKSILVER_OOZE

    ctx:add(hit.defender, component.WATER_HOLD, {
        by = hit.attacker,
        elapsed_aut = ctx:has(hit.defender, component.PLAYER) and 10 or 1,
        substance_id = watery and substances.WATER or substances.OOZE,
    })

    if ctx:has(hit.defender, component.PLAYER) then
        ctx:emit(channels.COMBAT, "The " .. hit.attacker_name ..
            " engulfs you" .. (watery and " in water!" or "!"))
    else
        ctx:emit(channels.COMBAT, "The " .. hit.attacker_name ..
            " engulfs the " .. hit.defender_definition.name ..
            (watery and " in water!" or "!"))
    end

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
    local health = ctx:get(state.by, component.HEALTH)

    if health and health.current > 0 and adjacent(holder, victim) then
        return false
    end

    ctx:remove(target, component.WATER_HOLD)

    if ctx:has(target, component.PLAYER) then
        if drowning.immune(ctx, target) then
            ctx:emit(channels.COMBAT,
                "The " .. state.substance_id ..
                " engulfing you falls away.")
        else
            ctx:emit(channels.COMBAT,
                "You gasp with relief as air once again reaches your lungs.")
        end
    end

    return true
end

-- Sweep every held target after movement so stale distant holds do not linger.
function engulf.release_far_all(ctx)
    for _, target in ipairs(ctx:query({ component.WATER_HOLD })) do
        engulf.release_far(ctx, target)
    end
end

-- The death phase can run after the water-hold tick. Remove links to the
-- dying actor before it is deleted, even if its victim has not acted yet.
function engulf.release_for(ctx, dying)
    for _, victim in ipairs(ctx:query({ component.WATER_HOLD })) do
        local state = ctx:get(victim, component.WATER_HOLD)

        if victim == dying then
            ctx:remove(victim, component.WATER_HOLD)
        elseif state.by == dying then
            engulf.release_far(ctx, victim)
        end
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

    return not drowning.immune(ctx, target)
end

-- The logarithmic stepdown mirrors the source's duration ramp. Reusing it
-- for both victims keeps each direction's different base damage clear.
local function stepdown(duration, threshold)
    return threshold * math.log(1 + duration / threshold) /
        math.log(2)
end

-- Player drowning runs on the player's own spent time. An unbreathing or
-- swimming player stays held and silenced only when breathing applies, but
-- its damage ramp resets so resistance cannot bank future damage.
local function tick_player(ctx, target, state, elapsed_aut)
    if drowning.immune(ctx, target) then
        state.elapsed_aut = 10
        ctx:set(target, component.WATER_HOLD, state)

        return 0
    end

    local delay = math.max(0, elapsed_aut or 0)

    state.elapsed_aut = state.elapsed_aut + delay
    ctx:set(target, component.WATER_HOLD, state)

    local numerator = math.floor((28 +
        stepdown(state.elapsed_aut, 28)) * delay)
    local damage = roll.random_divide(ctx, numerator, 100)

    player_health.damage(ctx, target, damage, false,
        state.by, causes.WATER)
    ctx:emit(channels.COMBAT, "Your lungs strain for air!")

    return damage
end

-- Source mon-ench increments the monster hold on its own active turn and
-- awards the damage to the actual holder, which can be an allied monster.
local function tick_monster(ctx, target, state)
    local monster, actor = definition(ctx, target)

    if not breathes(monster) then
        return 0
    end

    local speed = math.max(1, actor.speed)
    local advanced = roll.random_divide(ctx, 100,
        math.min(speed, 100))

    state.elapsed_aut = state.elapsed_aut + advanced
    ctx:set(target, component.WATER_HOLD, state)

    -- Source speed_to_duration draws again for injury after advancing the
    -- enchant. Two independent rounds matter at non-divisor speeds.
    local duration = roll.random_divide(ctx, 100,
        math.min(speed, 100))
    local numerator = math.floor((50 +
        stepdown(state.elapsed_aut, 30)) * duration)
    local damage = roll.random_divide(ctx, numerator, 100)

    if damage <= 0 then
        return 0
    end

    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 then
        return 0
    end

    health = monster_health.damage(ctx, target, damage,
        state.by, causes.WATER)
    ctx:emit(channels.COMBAT,
        "The " .. monster.name .. " is asphyxiated!")

    if health.current == 0 and targets.allied(ctx, state.by) then
        ctx:signal("player_kill", target)
    end

    return damage
end

-- Clear dead or distant links before either victim clock advances.
function engulf.tick(ctx, target, elapsed_aut)
    if engulf.release_far(ctx, target) then
        return 0
    end

    local state = ctx:get(target, component.WATER_HOLD)

    if not state then
        return 0
    end

    if ctx:has(target, component.PLAYER) then
        return tick_player(ctx, target, state, elapsed_aut)
    end

    return tick_monster(ctx, target, state)
end

effects.add(mutations.MUT_ENGULF, {
    [capabilities.ENGULF_ON_HIT] = engulf.capability,
})

return engulf
