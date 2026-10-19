-- transmutation is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "transmutation",
    entries = {
        {
            weight = 10,
            text = "Changing",
        },
        {
            weight = 10,
            text = "Evolution",
        },
        {
            weight = 10,
            text = "Forms",
        },
        {
            weight = 10,
            text = "Metamorphosis",
        },
        {
            weight = 10,
            text = "Moulding",
        },
        {
            weight = 10,
            text = "Permutations",
        },
        {
            weight = 10,
            text = "Reformation",
        },
        {
            weight = 10,
            text = "Sculpting",
        },
        {
            weight = 10,
            text = "Shapes",
        },
        {
            weight = 10,
            text = "Shapeshifting",
        },
        {
            weight = 10,
            text = "Shaping",
        },
        {
            weight = 10,
            text = "Transfiguration",
        },
        {
            weight = 10,
            text = "Transformation",
        },
        {
            weight = 10,
            text = "Transmigration",
        },
        {
            weight = 10,
            text = "Transmogrification",
        },
        {
            weight = 10,
            text = "Transmutation",
        },
        {
            weight = 10,
            text = "Variation",
        },
        {
            weight = 10,
            text = "the Figure",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
