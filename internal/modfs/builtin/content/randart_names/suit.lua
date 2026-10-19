-- _suit_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_suit_",
    entries = {
        {
            weight = 10,
            text = "Cups",
        },
        {
            weight = 10,
            text = "Pentacles",
        },
        {
            weight = 10,
            text = "Swords",
        },
        {
            weight = 10,
            text = "Wands",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
