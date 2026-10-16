local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")

local policy = {}

function policy.eligible(_, definition)
    return definition.class == classes.OBJ_WEAPONS and
        definition.generation.mode == "random"
end

function policy.weight(_, definition)
    return definition.generation.weight or 1
end

function policy.roll(_, _, _, result)
    result.plus = 4
end

catalog.register(classes.OBJ_WEAPONS, policy)

return policy
