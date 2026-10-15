local power = require("policy.magic.power")
local cap = require("policy.magic.cap")
local catalog = require("policy.catalog")

local range = {}

local constants = {
    LOS_RADIUS = 7,
    POLAR_VORTEX_RADIUS = 5,
}

local function bound(expression)
    local value = tonumber(expression) or constants[expression]

    if not value then
        error("unknown spell range expression " .. tostring(expression))
    end

    return value
end

-- Source: spl-util.cc:spell_range. Spell definitions retain the named C++
-- constants so the catalog remains traceable to spl-data.h.
function range.for_spell(ctx, player, spell)
    local minimum = bound(spell.min_range_expr)
    local maximum = bound(spell.max_range_expr)

    if maximum < 0 then
        return maximum
    end

    if minimum == maximum then
        return math.min(maximum, 7)
    end

    local power_cap = cap.for_spell(spell)
    local spell_power = power.cast(ctx, player, spell)

    if power_cap <= 0 then
        error("variable-range spell has no power cap: " .. spell.id)
    end

    if spell_power >= power_cap then
        return math.min(maximum, 7)
    end

    local scaled = math.floor((spell_power * (maximum - minimum) +
        math.floor(power_cap / 2)) / power_cap) + minimum

    return math.min(scaled, 7)
end

function range.run_policy(ctx, input)
    local spell = catalog.get("spells", input.spell_id)

    return {
        range = range.for_spell(ctx, ctx:player(), spell),
    }
end

register.policy({
    id = "magic.spell_range",
    run = range.run_policy,
})

return range
