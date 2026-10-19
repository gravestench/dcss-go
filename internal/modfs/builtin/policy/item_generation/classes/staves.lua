local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")

local policy = {}

-- Random staves and explicitly forced staves share one eligibility rule.
function policy.eligible(_, definition, request)
    return definition.class == classes.OBJ_STAVES and
        (definition.generation.mode == "random" or
            request.kind_id == definition.id and
            definition.generation.mode == "forced")
end

-- Example: policy.weight() returns one, keeping eligible staves uniformly weighted.
-- Staves have no subtype rarity table, so each eligible kind contributes one weight unit.
function policy.weight()
    -- Source: makeitem.cc, uniform over active staves.
    return 1
end

-- Staves need no post-selection quantity, brand, or charge draw.
function policy.roll()
end

catalog.register(classes.OBJ_STAVES, policy)

return policy
