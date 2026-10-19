-- Cloud immunity queries the live actor and the same monster definition used
-- by elemental damage. Specialized kinds add their own non-elemental rules.
local categories = require("constants.catalog")
local component = require("constants.component")
local catalog = require("policy.catalog")

local resistance = {}

-- Return zero for absent resistance entries so cloud immunity checks use a stable numeric level.
-- Example: an absent monster resistance entry contributes zero to a cloud immunity check.
function resistance.monster(ctx, actor, resistance_id)
    local state = ctx:get(actor, component.ACTOR)

    if not state then
        return 0
    end

    local definition = catalog.get(categories.MONSTERS, state.kind_id)

    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == resistance_id then
            return entry.level
        end
    end

    return 0
end

-- Use the shared spell resistance calculation for player cloud damage.
function resistance.player(ctx, actor, resistance_id)
    local damage = require("policy.magic.damage")

    return damage.player_resistance(ctx, actor, resistance_id)
end

return resistance
