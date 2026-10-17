local ids = require("ids.items")

local miscellany = {}

-- Source: shopping.cc:item_value, OBJ_MISCELLANY.
local fixed_value = {
    [ids.MISC_HORN_OF_GERYON] = 5000,
    [ids.MISC_ZIGGURAT] = 5000,
    [ids.MISC_PHIAL_OF_FLOODS] = 400,
    [ids.MISC_TIN_OF_TREMORSTONES] = 400,
    [ids.MISC_BOX_OF_BEASTS] = 400,
    [ids.MISC_CONDENSER_VANE] = 400,
    [ids.MISC_PHANTOM_MIRROR] = 400,
    [ids.MISC_LIGHTNING_ROD] = 300,
}

function miscellany.value(kind)
    return kind.shop_value or fixed_value[kind.id] or 200
end

return miscellany
