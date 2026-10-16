local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")

local policy = {}

function policy.eligible(_, definition, request)
    return definition.class == classes.OBJ_STAVES and
        (definition.generation.mode == "random" or
            request.kind_id == definition.id and
            definition.generation.mode == "forced")
end

function policy.weight()
    -- Source: makeitem.cc:1477-1491, uniform over active staves.
    return 1
end

function policy.roll()
end

catalog.register(classes.OBJ_STAVES, policy)

return policy
