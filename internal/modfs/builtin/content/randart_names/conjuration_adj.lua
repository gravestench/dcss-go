-- conjuration adj is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "conjuration adj",
    entries = {
        {
            weight = 10,
            text = "Combative",
        },
        {
            weight = 10,
            text = "Damaging",
        },
        {
            weight = 10,
            text = "Destructive",
        },
        {
            weight = 10,
            text = "Dynamic",
        },
        {
            weight = 10,
            text = "Energetic",
        },
        {
            weight = 10,
            text = "Excruciating",
        },
        {
            weight = 10,
            text = "Forceful",
        },
        {
            weight = 10,
            text = "Harmful",
        },
        {
            weight = 10,
            text = "Hurtful",
        },
        {
            weight = 10,
            text = "Injurious",
        },
        {
            weight = 10,
            text = "Kinetic",
        },
        {
            weight = 10,
            text = "Lethal",
        },
        {
            weight = 10,
            text = "Ruinous",
        },
        {
            weight = 10,
            text = "Violent",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
