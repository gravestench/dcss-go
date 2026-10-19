-- General Store (shops.SHOP_GENERAL) has shop selection weight 1 and
-- identifies stock: true.
-- Shop generation interprets class weights to create inventory entities;
-- purchases change the saved shop, not this type.

-- Source: crawl-ref/source/shop-type.h; shopping.cc:shop_type_name;
-- dungeon.cc:item_in_shop and _random_shop.
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local shops = require("ids.shops")

local definition = {
    id = shops.SHOP_GENERAL,
    name = "General Store",
    identifies_stock = true,
    generation_weight = 1,
    -- These class weights shape the stock of a General Store shop before
    -- individual items are rolled.
    class_weights = {
        { class = classes.OBJ_RANDOM, weight = 1 },
    },
}

register.definition(categories.SHOPS, definition)

return definition
