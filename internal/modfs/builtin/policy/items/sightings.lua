local identification = require("policy.items.identification")

local sightings = {}

function sightings.record(ctx, request)
    identification.record_seen(ctx, ctx:player(), request.kind_ids)

    return {}
end

register.policy({
    id = "character.record_seen_items",
    run = sightings.record,
})

return sightings
