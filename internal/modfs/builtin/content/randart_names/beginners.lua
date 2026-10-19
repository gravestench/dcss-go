-- _beginners_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_beginners_",
    entries = {
        {
            weight = 10,
            text = "Beginners",
        },
        {
            weight = 5,
            text = "Initiates",
        },
        {
            weight = 5,
            text = "Neophytes",
        },
        {
            weight = 5,
            text = "Novices",
        },
        {
            weight = 3,
            text = "Rookies",
        },
        {
            weight = 2,
            text = "Absolute Beginners",
        },
        {
            weight = 1,
            text = "Ex-Berserkers",
        },
        {
            weight = 1,
            text = "Dummies",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
