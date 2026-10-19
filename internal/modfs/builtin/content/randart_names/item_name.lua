-- _item_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_item_name_",
    entries = {
        {
            weight = 10,
            text = "Candelabrum",
        },
        {
            weight = 10,
            text = "Candle",
        },
        {
            weight = 10,
            text = "Chain",
        },
        {
            weight = 10,
            text = "Coin",
        },
        {
            weight = 10,
            text = "Cup",
        },
        {
            weight = 10,
            text = "Egg",
        },
        {
            weight = 10,
            text = "Feather",
        },
        {
            weight = 10,
            text = "Girdle",
        },
        {
            weight = 10,
            text = "Globe",
        },
        {
            weight = 10,
            text = "Horn",
        },
        {
            weight = 10,
            text = "Key",
        },
        {
            weight = 10,
            text = "Orb",
        },
        {
            weight = 10,
            text = "Pillar",
        },
        {
            weight = 10,
            text = "Purse",
        },
        {
            weight = 10,
            text = "Ring",
        },
        {
            weight = 10,
            text = "Scroll",
        },
        {
            weight = 10,
            text = "Ship",
        },
        {
            weight = 10,
            text = "Tent",
        },
        {
            weight = 10,
            text = "Vase",
        },
        {
            weight = 10,
            text = "Vine",
        },
        {
            weight = 10,
            text = "Walnut",
        },
        {
            weight = 10,
            text = "Wheel",
        },
        {
            weight = 10,
            text = "Yoke",
        },
        {
            weight = 10,
            text = "Brain",
        },
        {
            weight = 10,
            text = "Foot",
        },
        {
            weight = 10,
            text = "Hand",
        },
        {
            weight = 10,
            text = "Head",
        },
        {
            weight = 10,
            text = "Heart",
        },
        {
            weight = 10,
            text = "Kidney",
        },
        {
            weight = 10,
            text = "Mouth",
        },
        {
            weight = 10,
            text = "Throat",
        },
        {
            weight = 10,
            text = "Tooth",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
