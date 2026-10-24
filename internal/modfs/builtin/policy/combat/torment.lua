-- Source: spl-goditem.cc:torment_player and torment_cell.
local holiness = require("constants.monster_holiness")
local resistances = require("constants.resistance_ids")
local monster_resistance = require("policy.combat.monster_resistance")
local monster_profile = require("policy.combat.monster_profile")

local torment = {}

-- Monster holiness changes how much current HP Torment may remove.
local function has_holiness(definition, wanted)
    for _, value in ipairs(definition.holiness or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Read explicit torment resistance before computing the nonlethal HP loss.
local function resistance(definition, wanted)
    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == wanted then
            return entry.level
        end
    end

    return 0
end

-- Example: torment.susceptible(definition) with monster with torment resistance -> false susceptibility
-- Read torment resistance before computing a current-HP loss that cannot kill outright.
function torment.susceptible(definition)
    return resistance(definition, resistances.TORMENT) <= 0
end

-- Torment cannot kill directly; susceptible monsters lose a resistance-adjusted fraction of current HP.
function torment.monster_loss(ctx, monster, definition, current_hp)
    if not torment.susceptible(definition) then
        return 0
    end

    local negative = 3

    if has_holiness(definition, holiness.NATURAL) or
        has_holiness(definition, holiness.PLANT) then
        local profile = monster_profile.definition(ctx, monster, definition)

        negative = math.min(3,
            monster_resistance.level(ctx, monster, profile,
                resistances.NEGATIVE_ENERGY))
    end

    return math.max(0,
        math.floor(current_hp * (50 - negative * 5) / 100) - 1)
end

return torment
