-- _suspicion_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_suspicion_name_",
    entries = {
        {
            weight = 10,
            text = "@_suspicion_no_conflict_name_@",
        },
        {
            weight = 2,
            text = "@_conflict_name_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
