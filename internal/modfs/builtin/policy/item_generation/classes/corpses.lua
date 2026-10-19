local streams = require("constants.rng_streams")
local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")

local policy = {}

-- Corpse requests bypass ordinary subtype weights because their source monster identifies the result.
-- Example: policy.eligible(nil, corpse_kind,
--     { kind_id = corpse_kind.id, base_id = "MONS_ORC" }) accepts a forced corpse.
function policy.eligible(_, definition, request)
    return definition.class == classes.OBJ_CORPSES and
        definition.generation.mode == "forced" and
        request.kind_id == definition.id and
        type(request.base_id) == "string" and
        request.base_id ~= ""
end

-- Forced corpse requests never enter the random weighted pool.
function policy.weight()
    return 0
end

-- Store source monster ID and freshness on the corpse component.
function policy.roll(ctx, _, request, result)
    result.components["core.corpse"] = {
        monster_id = request.base_id,
        freshness = 110,
        appearance = ctx:random(streams.ITEM_GENERATION, 255) + 1,
    }
end

catalog.register(classes.OBJ_CORPSES, policy)

return policy
