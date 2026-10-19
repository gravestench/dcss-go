-- summoning owner is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "summoning owner",
    entries = {
        {
            weight = 10,
            text = "Mara",
        },
        {
            weight = 10,
            text = "__NONE",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
