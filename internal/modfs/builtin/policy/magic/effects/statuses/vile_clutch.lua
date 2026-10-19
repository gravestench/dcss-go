-- Source: spl-monench.cc:cast_vile_clutch, beam.cc:BEAM_VILE_CLUTCH,
-- actor.cc:constriction_damage_defender, and monster.cc:attempt_escape.
local time = require("constants.time")
local component = require("constants.component")
local terrain = require("constants.terrain")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local equipment = require("policy.combat.equipment")
local range = require("policy.magic.range")
local trajectory = require("policy.combat.trajectory")
local common = require("policy.magic.effects.statuses.common")

local clutch = {}

local unsafe_floor = {
    [terrain.DNGN_DEEP_WATER] = true,
    [terrain.DNGN_SHALLOW_WATER] = true,
    [terrain.DNGN_LAVA] = true,
}

-- Exclude insubstantial targets before attaching a physical clutch state.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Use stochastic rounding for grip power so low cast power still scales smoothly.
local function divide(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("spell", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

-- Example: an eligible monster struck by Vile Clutch becomes restrained and
-- takes increasing constriction damage after later player actions.
local function eligible(ctx, target, definition)
    local position = ctx:get(target, component.POSITION)
    local feature = ctx:cell(position.level_id, position.x, position.y)

    return not unsafe_floor[feature] and
        not has(definition.flags, "M_INSUBSTANTIAL") and
        not ctx:has(target, component.CONSTRICTION) and
        not ctx:has(target, component.MONSTER_VILE_CLUTCH)
end

-- Trace the aimed ray and attach restraint only to eligible actors it contacts.
function clutch.cast(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))

    for _, contact in ipairs(ray.contacts) do
        local target = contact.actor
        local actor = ctx:get(target, component.ACTOR)
        local health = ctx:get(target, component.HEALTH)

        if target ~= player and actor and health and health.current > 0 then
            local definition = catalog.get("monsters", actor.kind_id)

            if eligible(ctx, target, definition) then
                local bound = math.max(1, divide(ctx, power, 10))
                local rolled = math.floor((ctx:random("spell", bound) +
                    ctx:random("spell", bound + 1)) / 2)
                ctx:add(target, component.MONSTER_VILE_CLUTCH, {
                    remaining_aut = (4 + rolled) * time.AUT_PER_TURN,
                    power = power,
                    held_aut = 0,
                    escape_attempts = 0,
                })
                ctx:emit("warning", "Zombie hands grab the " ..
                    definition.name .. ".")
            end
        end
    end
end

-- A zero-duration component is no longer a live restraint even before cleanup removes it.
function clutch.restrained(ctx, monster)
    local state = ctx:get(monster, component.MONSTER_VILE_CLUTCH)

    return state ~= nil and state.remaining_aut > 0
end

-- Each escape attempt increases saved pressure against a fresh melee roll.
function clutch.escape(ctx, monster)
    local state = ctx:get(monster, component.MONSTER_VILE_CLUTCH)

    if not state or state.remaining_aut <= 0 then
        return true
    end

    state.escape_attempts = state.escape_attempts + 1
    local bound = 10 + divide(ctx, state.power, 5)
    local grip = 1 + ctx:random("melee", bound)

    if 3 * state.escape_attempts > grip then
        ctx:remove(monster, component.MONSTER_VILE_CLUTCH)
        ctx:emit("combat", "The zombie hands release their grip.")
        return true
    end

    ctx:set(monster, component.MONSTER_VILE_CLUTCH, state)
    return false
end

-- Decay restraint in aut and remove expired state before the next escape or damage check.
function clutch.tick_monster(ctx, monster)
    local state = ctx:get(monster, component.MONSTER_VILE_CLUTCH)

    if not state then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - time.AUT_PER_TURN)

    if state.remaining_aut == 0 then
        ctx:remove(monster, component.MONSTER_VILE_CLUTCH)
        ctx:emit("combat", "The zombie hands release their grip.")
    else
        ctx:set(monster, component.MONSTER_VILE_CLUTCH, state)
    end
end

-- Process held monsters after player actions; armour reduces each damage roll,
-- while elapsed AUT advances the saved grip ramp for the next action.
function clutch.damage_player_action(ctx, player, aut)
    local origin = ctx:get(player, component.POSITION)

    for _, monster in ipairs(ctx:query({
        component.MONSTER_VILE_CLUTCH, component.POSITION, component.HEALTH,
    })) do
        local state = ctx:get(monster, component.MONSTER_VILE_CLUTCH)
        local position = ctx:get(monster, component.POSITION)
        local health = ctx:get(monster, component.HEALTH)

        if health.current > 0 and
            common.visible(ctx, origin, position) then
            local definition = catalog.get("monsters",
                ctx:get(monster, component.ACTOR).kind_id)
            local sides = math.max(1, divide(ctx, 70 + state.power, 20))
            local base = 2 + ctx:random("melee", sides) +
                ctx:random("melee", sides)
            local ramp = divide(ctx,
                base * math.min(state.held_aut, 50), 50)
            local ac = math.max(0, definition.ac +
                equipment.protection_ac(ctx, monster))
            local amount = math.max(0, base + ramp -
                ctx:random("melee", 1 + math.floor(ac / 2)))

            if amount > 0 then
                damage.apply(ctx, monster, amount)
            end

            ctx:emit("combat", "The zombie hands constrict the " ..
                definition.name .. ".")
            state.held_aut = state.held_aut + aut
            ctx:set(monster, component.MONSTER_VILE_CLUTCH, state)
        end
    end
end

return clutch
