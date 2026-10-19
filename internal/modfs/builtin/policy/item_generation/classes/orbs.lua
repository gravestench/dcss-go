local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")

local policy = {}

-- Example: policy.eligible(nil, orb_kind, { kind_id = orb_kind.id }) accepts a forced orb request.
-- Orbs are forced requests; this class contributes no weighted random candidate.
function policy.eligible(_, definition, request)
    return definition.class == classes.OBJ_ORBS and
        definition.generation.mode == "forced" and
        request.kind_id == definition.id
end

-- Forced orbs cannot enter a random weighted class draw.
function policy.weight()
    return 0
end

-- The requested orb needs no extra per-instance fields.
function policy.roll()
end

catalog.register(classes.OBJ_ORBS, policy)

return policy
