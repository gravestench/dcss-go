local catalog = require("policy.catalog")
local properties = require("ids.artefact_properties")
local kinds = require("constants.artefact_kinds")

local artefacts = {}

-- Source: shopping.cc:artefact_value. Properties use their saved source IDs.
local linear = {
    [properties.AC] = 6,
    [properties.EVASION] = 6,
    [properties.SHIELDING] = 5,
    [properties.SLAYING] = 6,
    [properties.STRENGTH] = 3,
    [properties.INTELLIGENCE] = 3,
    [properties.DEXTERITY] = 3,
    [properties.HP] = 4,
    [properties.MAGICAL_POWER] = 3,
    [properties.STEALTH] = 2,
}

local positive = {
    [properties.POISON] = 6,
    [properties.ELECTRICITY] = 10,
    [properties.RCORR] = 8,
    [properties.RMUT] = 8,
    [properties.SEE_INVISIBLE] = 6,
    [properties.FLY] = 3,
    [properties.BLINK] = 10,
    [properties.INVISIBLE] = 10,
    [properties.RMSL] = 20,
    [properties.CLARITY] = 20,
    [properties.ARCHMAGI] = 20,
}

local negative = {
    [properties.ANGRY] = 3,
    [properties.CAUSE_TELEPORTATION] = 3,
    [properties.NOISE] = 5,
    [properties.PREVENT_TELEPORTATION] = 10,
    [properties.PREVENT_SPELLCASTING] = 10,
    [properties.CONTAM] = 8,
    [properties.CORRODE] = 8,
    [properties.DRAIN] = 8,
    [properties.SLOW] = 8,
    [properties.FRAGILE] = 8,
}

-- Positive resistance grows quadratically in value; a vulnerability incurs one fixed penalty.
local function resistance(value, base, scale, penalty)
    if value > 0 then
        return base + scale * value * value
    end

    return value < 0 and -penalty or 0
end

-- A known unique artefact can carry an authored fixed price; returning nil
-- lets ordinary artefacts continue through the calculated value path.
function artefacts.fixed_value(artefact)
    if not artefact or artefact.kind ~= kinds.UNIQUE then
        return nil
    end

    local definition = catalog.get("artefacts", artefact.unique_id)
    local fixed = definition.properties and definition.properties.value

    if type(fixed) == "number" and fixed > 0 then
        return fixed
    end

    return nil
end

-- Example: fire resistance adds its scaled bonus before negative properties reduce the shop valuation.
-- Walk typed artefact properties and flags with source multipliers so the
-- same saved roll is valued consistently across every equipment class.
function artefacts.value(artefact)

    local values = artefact.properties or {}
    local result = 10

    for id, weight in pairs(linear) do
        result = result + weight * (values[id] or 0)
    end

    result = result + resistance(values[properties.FIRE] or 0, 5, 5, 10)
    result = result + resistance(values[properties.COLD] or 0, 5, 5, 10)
    result = result + resistance(values[properties.WILLPOWER] or 0, 4, 4, 6)
    result = result + resistance(values[properties.NEGATIVE_ENERGY] or 0, 3, 3, 0)

    if (values[properties.STEALTH] or 0) > 0 then
        result = result + 2 * values[properties.STEALTH]
    end

    for id, weight in pairs(positive) do
        if (values[id] or 0) ~= 0 then
            result = result + weight
        end
    end

    for id, weight in pairs(negative) do
        if (values[id] or 0) ~= 0 then
            result = result - weight
        end
    end

    return math.max(0, result)
end

return artefacts
