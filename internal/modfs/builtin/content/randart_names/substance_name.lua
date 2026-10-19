-- _substance_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_substance_name_",
    entries = {
        {
            weight = 10,
            text = "Ash",
        },
        {
            weight = 10,
            text = "Bile",
        },
        {
            weight = 10,
            text = "Bloodstone",
        },
        {
            weight = 10,
            text = "Bodily Humours",
        },
        {
            weight = 10,
            text = "Bread",
        },
        {
            weight = 10,
            text = "Cheese",
        },
        {
            weight = 10,
            text = "Cobwebs",
        },
        {
            weight = 10,
            text = "Crystal",
        },
        {
            weight = 10,
            text = "Dried Tears",
        },
        {
            weight = 10,
            text = "Dung",
        },
        {
            weight = 10,
            text = "Ointment",
        },
        {
            weight = 10,
            text = "Oozing Pus",
        },
        {
            weight = 10,
            text = "Paper",
        },
        {
            weight = 10,
            text = "Rubbish",
        },
        {
            weight = 10,
            text = "Salt",
        },
        {
            weight = 10,
            text = "Saltpetre",
        },
        {
            weight = 10,
            text = "Sharkskin",
        },
        {
            weight = 10,
            text = "Slime",
        },
        {
            weight = 10,
            text = "Sulphur",
        },
        {
            weight = 10,
            text = "Terra Cotta",
        },
        {
            weight = 10,
            text = "Dust",
        },
        {
            weight = 10,
            text = "Mana",
        },
        {
            weight = 10,
            text = "Spores",
        },
        {
            weight = 10,
            text = "Yeast",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
