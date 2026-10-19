-- killer_name is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "killer_name",
    entries = {
        {
            weight = 10,
            text = "'s Bane",
        },
        {
            weight = 10,
            text = "'s Curse",
        },
        {
            weight = 10,
            text = "'s Death",
        },
        {
            weight = 10,
            text = "'s Doom",
        },
        {
            weight = 10,
            text = "'s Foe",
        },
        {
            weight = 10,
            text = "'s Peril",
        },
        {
            weight = 10,
            text = "'s Regret",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
