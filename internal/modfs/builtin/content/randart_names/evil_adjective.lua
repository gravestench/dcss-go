-- _evil_adjective_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_evil_adjective_",
    entries = {
        {
            weight = 10,
            text = "Black",
        },
        {
            weight = 10,
            text = "Blasphemous",
        },
        {
            weight = 10,
            text = "Dark",
        },
        {
            weight = 10,
            text = "Despicable",
        },
        {
            weight = 10,
            text = "Evil",
        },
        {
            weight = 10,
            text = "Iniquitous",
        },
        {
            weight = 10,
            text = "Left-Handed",
        },
        {
            weight = 10,
            text = "Maleficent",
        },
        {
            weight = 10,
            text = "Malignant",
        },
        {
            weight = 10,
            text = "Profane",
        },
        {
            weight = 10,
            text = "Sinister",
        },
        {
            weight = 10,
            text = "Unhallowed",
        },
        {
            weight = 10,
            text = "Unholy",
        },
        {
            weight = 10,
            text = "Wicked",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
