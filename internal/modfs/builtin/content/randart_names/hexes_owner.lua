-- hexes owner is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "hexes owner",
    entries = {
        {
            weight = 10,
            text = "Yara",
        },
        {
            weight = 1,
            text = "Terpsichore",
        },
        {
            weight = 10,
            text = "Tukima",
        },
        {
            weight = 10,
            text = "__NONE",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
