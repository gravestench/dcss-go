-- _evil_being_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_evil_being_",
    entries = {
        {
            weight = 10,
            text = "Demons",
        },
        {
            weight = 10,
            text = "Greater Demons",
        },
        {
            weight = 10,
            text = "Lesser Demons",
        },
        {
            weight = 10,
            text = "Tempters",
        },
        {
            weight = 10,
            text = "Vampiric Thralls",
        },
        {
            weight = 5,
            text = "the Archfiend",
        },
        {
            weight = 10,
            text = "the Demon Prince",
        },
        {
            weight = 10,
            text = "the Devil",
        },
        {
            weight = 10,
            text = "the Devil's Advocate",
        },
        {
            weight = 10,
            text = "the Devil's Team",
        },
        {
            weight = 10,
            text = "the Evil One",
        },
        {
            weight = 10,
            text = "the Fiend",
        },
        {
            weight = 10,
            text = "the Furies",
        },
        {
            weight = 10,
            text = "the Imp",
        },
        {
            weight = 10,
            text = "the Iron Devil",
        },
        {
            weight = 10,
            text = "the Lich-sworn",
        },
        {
            weight = 10,
            text = "the Little Devil",
        },
        {
            weight = 10,
            text = "the Prince of Darkness",
        },
        {
            weight = 10,
            text = "the Tormentor",
        },
        {
            weight = 10,
            text = "the Villain",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
