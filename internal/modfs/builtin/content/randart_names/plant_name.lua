-- _plant_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_plant_name_",
    entries = {
        {
            weight = 10,
            text = "Eggplant",
        },
        {
            weight = 10,
            text = "Chickpea",
        },
        {
            weight = 10,
            text = "Lettuce",
        },
        {
            weight = 10,
            text = "Radish",
        },
        {
            weight = 10,
            text = "Sugar Beet",
        },
        {
            weight = 10,
            text = "Shallot",
        },
        {
            weight = 10,
            text = "Tomato",
        },
        {
            weight = 10,
            text = "Turnip",
        },
        {
            weight = 10,
            text = "Whelk",
        },
        {
            weight = 5,
            text = "Magic Mushroom",
        },
        {
            weight = 10,
            text = "Mushroom",
        },
        {
            weight = 10,
            text = "Puffball",
        },
        {
            weight = 10,
            text = "Slime-mould",
        },
        {
            weight = 10,
            text = "Toadstool",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
