-- _philosophy_or_science_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_philosophy_or_science_",
    entries = {
        {
            weight = 10,
            text = "@_philosophy_name_@",
        },
        {
            weight = 10,
            text = "@_science_name_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
