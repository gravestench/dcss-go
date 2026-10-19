-- _long_killer_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_long_killer_name_",
    entries = {
        {
            weight = 10,
            text = "'s Death Toll",
        },
        {
            weight = 10,
            text = "'s Demise",
        },
        {
            weight = 10,
            text = "'s Funeral",
        },
        {
            weight = 10,
            text = "'s Nightmare",
        },
        {
            weight = 10,
            text = "'s Undoing",
        },
        {
            weight = 1,
            text = "'s Looming Annihilation",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
