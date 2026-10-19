local classes = require("ids.object_classes")

local fixed = {}

-- Source: shopping.cc:item_value for classes without per-kind rules.
local values = {
    [classes.OBJ_ORBS] = 250000,
    [classes.OBJ_RUNES] = 10000,
}

-- Example: fixed.value(staff_kind, nil, { type = false }) values an unknown staff at 120.
-- Use class-specific fixed prices for these items because their value is not
-- driven by the weapon or armour enchantment formulas.
function fixed.value(kind, _, known)
    if kind.shop_value ~= nil then
        return kind.shop_value
    end

    if kind.class == classes.OBJ_STAVES then
        return known.type and 250 or 120
    end

    return values[kind.class] or 0
end

return fixed
