local identification = require("policy.items.identification")
local zin = require("policy.religion.gods.zin")

local sightings = {}

-- A sighting updates player knowledge when an item is observed in the world.
-- Example: sightings.record(ctx, { kind_ids = { "WPN_LONG_SWORD" } }) records a seen weapon type.
function sightings.record(ctx, request)
    local player = ctx:player()

    identification.record_seen(ctx, player, request.kind_ids)

    -- Source gold remembers the god at first sight. The Go visibility host
    -- passes only currently visible floor item IDs, never mapped cells.
    for _, id in ipairs(request.floor_item_ids or {}) do
        local entity = ctx:entity(id)

        if entity then
            zin.mark_seen(ctx, player, entity)
        end
    end

    return {}
end

register.policy({
    id = "character.record_seen_items",
    run = sightings.record,
})

return sightings
