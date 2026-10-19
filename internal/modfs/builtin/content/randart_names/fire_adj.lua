-- fire adj is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "fire adj",
    entries = {
        {
            weight = 10,
            text = "Blazing",
        },
        {
            weight = 10,
            text = "Blistering",
        },
        {
            weight = 10,
            text = "Burning",
        },
        {
            weight = 5,
            text = "Calescent",
        },
        {
            weight = 5,
            text = "Calid",
        },
        {
            weight = 5,
            text = "Calorific",
        },
        {
            weight = 10,
            text = "Charred",
        },
        {
            weight = 10,
            text = "Conflagrant",
        },
        {
            weight = 10,
            text = "Fiery",
        },
        {
            weight = 10,
            text = "Flaming",
        },
        {
            weight = 10,
            text = "Flamy",
        },
        {
            weight = 10,
            text = "Heated",
        },
        {
            weight = 10,
            text = "Hot",
        },
        {
            weight = 10,
            text = "Igneous",
        },
        {
            weight = 10,
            text = "Incandescent",
        },
        {
            weight = 10,
            text = "Incendiary",
        },
        {
            weight = 10,
            text = "Molten",
        },
        {
            weight = 10,
            text = "Red-Hot",
        },
        {
            weight = 10,
            text = "Searing",
        },
        {
            weight = 10,
            text = "Scorched",
        },
        {
            weight = 10,
            text = "Scorching",
        },
        {
            weight = 10,
            text = "Singed",
        },
        {
            weight = 10,
            text = "Sweltering",
        },
        {
            weight = 10,
            text = "Torrid",
        },
        {
            weight = 1,
            text = "Well-Done",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
