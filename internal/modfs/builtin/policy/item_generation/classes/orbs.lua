local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")

local policy = {}

function policy.eligible(_, definition, request)
    return definition.class == classes.OBJ_ORBS and
        definition.generation.mode == "forced" and
        request.kind_id == definition.id
end

function policy.weight()
    return 0
end

function policy.roll()
end

catalog.register(classes.OBJ_ORBS, policy)

return policy
