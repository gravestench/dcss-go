-- _evil_noun_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_evil_noun_",
    entries = {
        {
            weight = 10,
            text = "Arts",
        },
        {
            weight = 10,
            text = "Deeds",
        },
        {
            weight = 10,
            text = "Liturgies",
        },
        {
            weight = 10,
            text = "Magic",
        },
        {
            weight = 1,
            text = "Magicks",
        },
        {
            weight = 10,
            text = "Mysteries",
        },
        {
            weight = 10,
            text = "Rites",
        },
        {
            weight = 10,
            text = "Rituals",
        },
        {
            weight = 10,
            text = "Secrets",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
