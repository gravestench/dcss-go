-- _power_or_anger_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_power_or_anger_",
    entries = {
        {
            weight = 10,
            text = "@_power_name_@",
        },
        {
            weight = 7,
            text = "@_conflict_name_@",
        },
        {
            weight = 7,
            text = "@_anger_name_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
