local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")

local policy = {}

-- Example: policy.eligible(nil, rune_kind, { kind_id = rune_kind.id }) accepts a forced rune request.
-- Rune requests carry their specific rune ID instead of drawing from a depth-weighted pool.
function policy.eligible(_, definition, request)
    return definition.class == classes.OBJ_RUNES and
        definition.generation.mode == "forced" and
        request.kind_id == definition.id
end

-- Runes only arise from explicit forced requests.
function policy.weight()
    return 0
end

-- The requested rune kind carries all its static item fields.
function policy.roll()
end

catalog.register(classes.OBJ_RUNES, policy)

return policy
