-- _strategy_or_justice_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_strategy_or_justice_",
    entries = {
        {
            weight = 2,
            text = "@_strategy_name_@",
        },
        {
            weight = 4,
            text = "@_valour_name_@",
        },
        {
            weight = 3,
            text = "@_justice_name_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
