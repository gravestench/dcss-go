-- Source: attack.cc:SPWPN_CONFUSE and beam.cc:BEAM_CONFUSION.
local component = require("constants.component")
local will = require("policy.magic.effects.zaps.will")
local roll = require("policy.combat.roll")
local monster_stats = require("policy.combat.monster_stats")
local senses = require("policy.character.senses")
local vault_enchantments = require("policy.monsters.vault_enchantments")
local enchantments = require("constants.vault_monster_enchantments")

local touch = {}

-- Step down high power before storing confusion duration to avoid linear late-game growth.
local function duration(power)
    -- beam.cc:_ench_pow_to_dur uses stepdown(power * BASELINE_DELAY, 70).
    local stepped = 70 * math.log(1 + power * 10 / 70) / math.log(2)
    return math.floor(stepped + 0.5)
end

-- Check life and will resistance before creating monster confusion state.
function touch.apply(ctx, target, definition, power, source)
    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 then
        return false, true
    end

    if will.resists(ctx, definition, power,
        target, nil, source) then
        return false, false
    end

    touch.apply_unresisted(ctx, target, definition, power)

    return true, false
end

-- The beam and melee paths share status duration after their own hit and
-- resistance checks. This helper never performs a second saving throw.
function touch.apply_unresisted(ctx, target, definition, power)

    local current = ctx:get(target, component.MONSTER_CONFUSION)
    local remaining = math.max(current and current.remaining_aut or 0,
        duration(power))
    local next_state = { remaining_aut = remaining }

    if current then
        ctx:set(target, component.MONSTER_CONFUSION, next_state)
    else
        ctx:add(target, component.MONSTER_CONFUSION, next_state)
    end

    ctx:emit("spell", "The " .. definition.name .. " appears confused.")

end

-- Monster Mass Confusion supplies an explicit five-to-seven-turn duration
-- after its own will contest. It must not feed that duration through the
-- beam power stepdown used by Confusing Touch.
function touch.apply_turns(ctx, target, definition, turns)
    local current = ctx:get(target, component.MONSTER_CONFUSION)
    local remaining = math.max(current and current.remaining_aut or 0,
        turns * 10)
    local next_state = { remaining_aut = remaining }

    if current then
        ctx:set(target, component.MONSTER_CONFUSION, next_state)
    else
        ctx:add(target, component.MONSTER_CONFUSION, next_state)
    end

    if senses.player_sees_actor(ctx, target) then
        ctx:emit("spell", "The " .. definition.name ..
            " appears confused.")
    end
end

-- Source: spl-other.cc:_intoxicate_monsters adds ENCH_CONFUSION with an
-- implicit duration. mon-ench.cc:calc_duration supplies the monster clock.
function touch.apply_innate(ctx, target, definition)
    local actor = ctx:get(target, component.ACTOR)
    local speed = math.max(1, actor.speed)
    local hd = monster_stats.hit_dice(ctx, target, definition)
    local scaled_speed = math.max(1, math.floor((hd + 5) * 10 / speed))
    local centiturns = math.max(3, math.floor(100 / scaled_speed))
    local raw = centiturns * roll.random_divide(ctx, 100, speed)
    local low = math.floor(raw * 60 / 100)
    local high = math.floor(raw * 40 / 100)
    local fuzz = roll.average_two(ctx, "melee", low + high + 1)
    local added = math.max(15, raw + fuzz - low)
    local current = ctx:get(target, component.MONSTER_CONFUSION)
    local next_state = {
        remaining_aut = (current and current.remaining_aut or 0) + added,
    }

    if current then
        ctx:set(target, component.MONSTER_CONFUSION, next_state)
    else
        ctx:add(target, component.MONSTER_CONFUSION, next_state)
    end
end

-- Treat an expired component as inactive before the scheduler's cleanup tick.
function touch.active(ctx, target)
    local current = ctx:get(target, component.MONSTER_CONFUSION)

    return current ~= nil and current.remaining_aut > 0
end

-- Example: A confusion mark with ten aut expires at the next monster tick.
-- Decay confusion by one turn and remove the component once scheduling can no longer consult it.
function touch.tick(ctx, target)
    local current = ctx:get(target, component.MONSTER_CONFUSION)

    if not current or
        vault_enchantments.active(ctx, target, enchantments.CONFUSION) or
        vault_enchantments.active(ctx, target, enchantments.MAD) then
        return
    end

    current.remaining_aut = current.remaining_aut - 10

    if current.remaining_aut <= 0 then
        ctx:remove(target, component.MONSTER_CONFUSION)
        return
    end

    ctx:set(target, component.MONSTER_CONFUSION, current)
end

return touch
