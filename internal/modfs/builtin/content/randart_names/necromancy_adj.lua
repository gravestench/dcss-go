-- necromancy adj is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "necromancy adj",
    entries = {
        {
            weight = 10,
            text = "Bloody",
        },
        {
            weight = 10,
            text = "Dark",
        },
        {
            weight = 10,
            text = "Deathly",
        },
        {
            weight = 10,
            text = "Doomed",
        },
        {
            weight = 10,
            text = "Evil",
        },
        {
            weight = 10,
            text = "Ghastly",
        },
        {
            weight = 10,
            text = "Ghoulish",
        },
        {
            weight = 10,
            text = "Grim",
        },
        {
            weight = 10,
            text = "Grisly",
        },
        {
            weight = 10,
            text = "Lethal",
        },
        {
            weight = 10,
            text = "Loathsome",
        },
        {
            weight = 10,
            text = "Macabre",
        },
        {
            weight = 10,
            text = "Morbid",
        },
        {
            weight = 10,
            text = "Mortuary",
        },
        {
            weight = 10,
            text = "Necrotic",
        },
        {
            weight = 10,
            text = "Sepulchral",
        },
        {
            weight = 10,
            text = "Shadowy",
        },
        {
            weight = 10,
            text = "Sinister",
        },
        {
            weight = 10,
            text = "Twisted",
        },
        {
            weight = 10,
            text = "Unholy",
        },
        {
            weight = 10,
            text = "Vile",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
