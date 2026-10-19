local identification = require("policy.items.identification")

local sightings = {}

-- A sighting updates player knowledge when an item is observed in the world.
-- Example: sightings.record(ctx, { kind_ids = { "WPN_LONG_SWORD" } }) records a seen weapon type.
function sightings.record(ctx, request)
    identification.record_seen(ctx, ctx:player(), request.kind_ids)

    return {}
end

register.policy({
    id = "character.record_seen_items",
    run = sightings.record,
})

return sightings
