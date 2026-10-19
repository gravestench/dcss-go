local ids = require("constants.monster_construct_components")
local resistances = require("constants.resistance_ids")

local resistance = {}
local elements = {
    resistances.FIRE,
    resistances.COLD,
    resistances.ELECTRICITY,
    resistances.POISON,
    resistances.ACID,
}

-- monster.cc:ENCH_RESISTANCE adds one elemental level. Project a fresh
-- array so a temporary enchantment never mutates the shared species.
function resistance.project(ctx, entity, definition)
    local state = ctx:get(entity, ids.RESISTANCE)

    if not state or state.remaining_aut <= 0 or
        definition.resistance_projected_for == entity then
        return definition
    end

    local result = {}
    local levels = {}

    for key, value in pairs(definition) do
        result[key] = value
    end

    for _, entry in ipairs(definition.resistances or {}) do
        levels[entry.id] = entry.level
    end

    for _, id in ipairs(elements) do
        levels[id] = math.min(3, (levels[id] or 0) + 1)
    end

    local ordered = {}

    for id in pairs(levels) do
        ordered[#ordered + 1] = id
    end

    table.sort(ordered)
    result.resistance_projected_for = entity
    result.resistances = {}

    for _, id in ipairs(ordered) do
        result.resistances[#result.resistances + 1] = {
            id = id,
            level = levels[id],
        }
    end

    return result
end

return resistance
