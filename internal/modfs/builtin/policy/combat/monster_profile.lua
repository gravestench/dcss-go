-- Most monsters use immutable catalog definitions. A player illusion is the
-- exception: the saved actor owns a ghost snapshot made when Mara cast.
local component = require("constants.component")

local profile = {}

-- Project saved per-actor values into the same read shape as a catalog
-- monster. Consumers use their ordinary combat rules after this one read.
function profile.definition(ctx, entity, definition)
    local ghost = ctx:get(entity, component.PLAYER_ILLUSION)

    if not ghost then
        return definition
    end

    local result = {}

    for key, value in pairs(definition) do
        result[key] = value
    end

    result.name = ghost.name .. "'s illusion"
    result.ac = ghost.ac
    result.ev = ghost.ev
    result.holiness = { ghost.holiness_id }
    result.attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = ghost.damage,
        },
    }

    local ids = {}

    for id in pairs(ghost.resistances) do
        ids[#ids + 1] = id
    end

    table.sort(ids)

    result.resistances = {}

    for _, id in ipairs(ids) do
        result.resistances[#result.resistances + 1] = {
            id = id,
            level = ghost.resistances[id],
        }
    end

    return result
end

return profile
