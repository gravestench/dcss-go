-- Source: spl-goditem.cc:torment_player and torment_cell.
local holiness = require("constants.monster_holiness")
local resistances = require("constants.resistance_ids")

local torment = {}

local function has_holiness(definition, wanted)
    for _, value in ipairs(definition.holiness or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function resistance(definition, wanted)
    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == wanted then
            return entry.level
        end
    end

    return 0
end

function torment.susceptible(definition)
    return resistance(definition, resistances.TORMENT) <= 0
end

function torment.monster_loss(definition, current_hp)
    if not torment.susceptible(definition) then
        return 0
    end

    local negative = 3

    if has_holiness(definition, holiness.NATURAL) or
        has_holiness(definition, holiness.PLANT) then
        negative = math.min(3,
            resistance(definition, resistances.NEGATIVE_ENERGY))
    end

    return math.max(0,
        math.floor(current_hp * (50 - negative * 5) / 100) - 1)
end

return torment
