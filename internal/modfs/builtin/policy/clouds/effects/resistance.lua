-- Cloud immunity queries the live actor and the same monster definition used
-- by elemental damage. Specialized kinds add their own non-elemental rules.
local categories = require("constants.catalog")
local component = require("constants.component")
local catalog = require("policy.catalog")

local resistance = {}

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

function resistance.player(ctx, actor, resistance_id)
    local damage = require("policy.magic.damage")

    return damage.player_resistance(ctx, actor, resistance_id)
end

return resistance
