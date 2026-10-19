local ids = require("ids.items")

local wands = {}

-- Source: shopping.cc:item_value, OBJ_WANDS. The port stores source wand
-- plus as charges in core.item.charges.
local per_charge = {
    [ids.WAND_ACID] = 42,
    [ids.WAND_LIGHT] = 42,
    [ids.WAND_QUICKSILVER] = 42,
    [ids.WAND_DIGGING] = 42,
    [ids.WAND_ICEBLAST] = 24,
    [ids.WAND_ROOTS] = 24,
    [ids.WAND_CHARMING] = 24,
    [ids.WAND_PARALYSIS] = 24,
    [ids.WAND_POLYMORPH] = 14,
    [ids.WAND_MINDBURST] = 14,
    [ids.WAND_FLAME] = 7,
}

-- Example: wands.value(kind, wand, { type = true }) multiplies its per-charge price by wand.charges.
-- Price charges separately from wand type knowledge, because a wand's saved
-- charge count changes after use while its catalog identity does not.
function wands.value(kind, item, known)
    if kind.shop_value ~= nil then
        return kind.shop_value * item.charges
    end

    if not known.type then
        return 40
    end

    return (per_charge[kind.id] or 4) * item.charges
end

return wands
