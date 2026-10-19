-- divine_esteem is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "divine_esteem",
    entries = {
        {
            weight = 10,
            text = "Approval",
        },
        {
            weight = 10,
            text = "Benevolence",
        },
        {
            weight = 10,
            text = "Delight",
        },
        {
            weight = 10,
            text = "Esteem",
        },
        {
            weight = 10,
            text = "Favour",
        },
        {
            weight = 5,
            text = "Felicitations",
        },
        {
            weight = 10,
            text = "Generosity",
        },
        {
            weight = 10,
            text = "Grace",
        },
        {
            weight = 10,
            text = "Hope",
        },
        {
            weight = 10,
            text = "Inspiration",
        },
        {
            weight = 10,
            text = "Pride",
        },
        {
            weight = 10,
            text = "Regard",
        },
        {
            weight = 5,
            text = "Respect",
        },
        {
            weight = 10,
            text = "Supremacy",
        },
        {
            weight = 10,
            text = "Whim",
        },
        {
            weight = 10,
            text = "Castigation",
        },
        {
            weight = 10,
            text = "Condemnation",
        },
        {
            weight = 10,
            text = "Displeasure",
        },
        {
            weight = 10,
            text = "Envy",
        },
        {
            weight = 10,
            text = "Reproof",
        },
        {
            weight = 70,
            text = "@_anger_quality_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
