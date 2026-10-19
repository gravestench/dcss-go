local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.items")

local policy = {}

-- Source: crawl-ref/source/makeitem.cc.
local source_items = {
    [ids.MISC_PHIAL_OF_FLOODS] = true,
    [ids.MISC_LIGHTNING_ROD] = true,
    [ids.MISC_BOX_OF_BEASTS] = true,
    [ids.MISC_PHANTOM_MIRROR] = true,
    [ids.MISC_TIN_OF_TREMORSTONES] = true,
    [ids.MISC_CONDENSER_VANE] = true,
    [ids.MISC_XOMS_CHESSBOARD] = true,
}

-- A forced miscellaneous kind may bypass ordinary source-item weights.
function policy.eligible(_, definition, request)
    if definition.class ~= classes.OBJ_MISCELLANY then
        return false
    end

    if request.kind_id == definition.id then
        return definition.generation.mode ~= "none"
    end

    return definition.generation.mode == "random" and
        policy.weight(nil, definition) > 0
end

-- Example: policy.weight(nil, phial_kind) falls back to weight one for a source miscellany item.
-- Unweighted source items remain drawable, while an unweighted extension gets no implicit chance.
function policy.weight(_, definition)
    return definition.generation.weight or
        (source_items[definition.id] and 1 or 0)
end

-- Miscellany has no per-instance roll after its kind is chosen.
function policy.roll()
end

catalog.register(classes.OBJ_MISCELLANY, policy)

return policy
