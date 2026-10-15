-- Source: attack.cc:SPWPN_CONFUSE and beam.cc:BEAM_CONFUSION.
local component = require("constants.component")
local will = require("policy.magic.effects.zaps.will")
local roll = require("policy.combat.roll")
local monster_stats = require("policy.combat.monster_stats")

local touch = {}

local function duration(power)
    -- beam.cc:_ench_pow_to_dur uses stepdown(power * BASELINE_DELAY, 70).
    local stepped = 70 * math.log(1 + power * 10 / 70) / math.log(2)
    return math.floor(stepped + 0.5)
end

function touch.apply(ctx, target, definition, power)
    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 then
        return false, true
    end

    if will.resists(ctx, definition, power, target) then
        return false, false
    end

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

    return true, false
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

function touch.active(ctx, target)
    local current = ctx:get(target, component.MONSTER_CONFUSION)

    return current ~= nil and current.remaining_aut > 0
end

function touch.tick(ctx, target)
    local current = ctx:get(target, component.MONSTER_CONFUSION)

    if not current then
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
