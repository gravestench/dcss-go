-- _diviner_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_diviner_name_",
    entries = {
        {
            weight = 10,
            text = "Augurer",
        },
        {
            weight = 10,
            text = "Fortune-Teller",
        },
        {
            weight = 10,
            text = "Oracle",
        },
        {
            weight = 10,
            text = "Seeker",
        },
        {
            weight = 10,
            text = "Seer",
        },
        {
            weight = 10,
            text = "Soothsayer",
        },
        {
            weight = 10,
            text = "Sybil",
        },
        {
            weight = 10,
            text = "Visionary",
        },
        {
            weight = 10,
            text = "Water Diviner",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
