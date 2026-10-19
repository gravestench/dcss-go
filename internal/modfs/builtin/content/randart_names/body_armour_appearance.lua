-- body armour appearance is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "body armour appearance",
    entries = {
        {
            weight = 3,
            text = "smelly",
        },
        {
            weight = 3,
            text = "bronze",
        },
        {
            weight = 2,
            text = "@_gemstone_@-studded",
        },
        {
            weight = 10,
            text = "@_gemstone_@-encrusted",
        },
        {
            weight = 200,
            text = "@armour appearance@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
