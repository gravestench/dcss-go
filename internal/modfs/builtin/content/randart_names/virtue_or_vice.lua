-- _virtue_or_vice_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_virtue_or_vice_",
    entries = {
        {
            weight = 5,
            text = "@_virtue_name_@",
        },
        {
            weight = 10,
            text = "@_valour_name_@",
        },
        {
            weight = 10,
            text = "@_vice_name_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
