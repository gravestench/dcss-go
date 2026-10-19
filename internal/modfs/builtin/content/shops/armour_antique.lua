-- Antique Armour (shops.SHOP_ARMOUR_ANTIQUE) has shop selection weight 1 and
-- identifies stock: false.
-- Shop generation interprets class weights to create inventory entities;
-- purchases change the saved shop, not this type.

-- Source: crawl-ref/source/shop-type.h; shopping.cc:shop_type_name;
-- dungeon.cc:item_in_shop and _random_shop.
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local shops = require("ids.shops")

local definition = {
    id = shops.SHOP_ARMOUR_ANTIQUE,
    name = "Antique Armour",
    identifies_stock = false,
    generation_weight = 1,
    -- These class weights shape the stock of a Antique Armour shop before
    -- individual items are rolled.
    class_weights = {
        { class = classes.OBJ_ARMOUR, weight = 1 },
    },
}

register.definition(categories.SHOPS, definition)

return definition
