local streams = require("constants.rng_streams")
local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")

local policy = {}

function policy.eligible(_, definition, request)
    return definition.class == classes.OBJ_CORPSES and
        definition.generation.mode == "forced" and
        request.kind_id == definition.id and
        type(request.base_id) == "string" and
        request.base_id ~= ""
end

function policy.weight()
    return 0
end

function policy.roll(ctx, _, request, result)
    result.components["core.corpse"] = {
        monster_id = request.base_id,
        freshness = 110,
        appearance = ctx:random(streams.ITEM_GENERATION, 255) + 1,
    }
end

catalog.register(classes.OBJ_CORPSES, policy)

return policy
