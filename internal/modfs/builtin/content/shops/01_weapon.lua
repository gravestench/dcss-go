-- Source: crawl-ref/source/shop-type.h; shopping.cc:shop_type_name;
-- dungeon.cc:item_in_shop and _random_shop.
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local shops = require("ids.shops")

local definition = {
    id = shops.SHOP_WEAPON,
    name = "Weapon",
    identifies_stock = true,
    generation_weight = 1,
    class_weights = {
        { class = classes.OBJ_WEAPONS, weight = 4 },
        { class = classes.OBJ_MISSILES, weight = 1 },
    },
}

register.definition(categories.SHOPS, definition)

return definition
