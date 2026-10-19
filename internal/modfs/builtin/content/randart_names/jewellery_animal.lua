-- _jewellery_animal_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_jewellery_animal_",
    entries = {
        {
            weight = 10,
            text = "Death Scarab",
        },
        {
            weight = 10,
            text = "Firefly",
        },
        {
            weight = 10,
            text = "Scarab",
        },
        {
            weight = 5,
            text = "Magpie",
        },
        {
            weight = 5,
            text = "Raven",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
