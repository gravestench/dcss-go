-- _anger_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_anger_name_",
    entries = {
        {
            weight = 10,
            text = "@_anger_quality_@",
        },
        {
            weight = 3,
            text = "@_anger_possessive_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
