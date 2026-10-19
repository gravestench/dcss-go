-- okawaru body armour is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "okawaru body armour",
    entries = {
        {
            weight = 10,
            text = "@Okawaru armour@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
