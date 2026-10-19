-- _catastrophe_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_catastrophe_name_",
    entries = {
        {
            weight = 10,
            text = "Earthquakes",
        },
        {
            weight = 10,
            text = "Cataclysm",
        },
        {
            weight = 10,
            text = "Drought",
        },
        {
            weight = 10,
            text = "Floods",
        },
        {
            weight = 10,
            text = "Ruination",
        },
        {
            weight = 10,
            text = "the Inferno",
        },
        {
            weight = 10,
            text = "Annihilation",
        },
        {
            weight = 10,
            text = "Armageddon",
        },
        {
            weight = 10,
            text = "Fimbulwinter",
        },
        {
            weight = 10,
            text = "Ragnarok",
        },
        {
            weight = 10,
            text = "World Downfall",
        },
        {
            weight = 10,
            text = "World's End",
        },
        {
            weight = 10,
            text = "the Apocalypse",
        },
        {
            weight = 10,
            text = "the End of Times",
        },
        {
            weight = 10,
            text = "Famine",
        },
        {
            weight = 10,
            text = "Pestilence",
        },
        {
            weight = 10,
            text = "Plague",
        },
        {
            weight = 10,
            text = "War",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
