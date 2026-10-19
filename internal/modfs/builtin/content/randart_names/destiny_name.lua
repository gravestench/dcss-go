-- _destiny_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_destiny_name_",
    entries = {
        {
            weight = 10,
            text = "Causality",
        },
        {
            weight = 10,
            text = "Destiny",
        },
        {
            weight = 10,
            text = "Doom",
        },
        {
            weight = 10,
            text = "Fate",
        },
        {
            weight = 10,
            text = "Karma",
        },
        {
            weight = 10,
            text = "Kismet",
        },
        {
            weight = 10,
            text = "Wyrd",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
