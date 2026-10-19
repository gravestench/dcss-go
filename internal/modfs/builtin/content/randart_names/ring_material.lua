-- _ring material_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_ring material_",
    entries = {
        {
            weight = 10,
            text = "wooden",
        },
        {
            weight = 10,
            text = "ivory",
        },
        {
            weight = 10,
            text = "bone",
        },
        {
            weight = 10,
            text = "amber",
        },
        {
            weight = 10,
            text = "silver",
        },
        {
            weight = 10,
            text = "golden",
        },
        {
            weight = 10,
            text = "platinum",
        },
        {
            weight = 10,
            text = "iron",
        },
        {
            weight = 10,
            text = "steel",
        },
        {
            weight = 10,
            text = "bronze",
        },
        {
            weight = 10,
            text = "brass",
        },
        {
            weight = 10,
            text = "copper",
        },
        {
            weight = 10,
            text = "tin",
        },
        {
            weight = 10,
            text = "lead",
        },
        {
            weight = 10,
            text = "pewter",
        },
        {
            weight = 10,
            text = "granite",
        },
        {
            weight = 10,
            text = "marble",
        },
        {
            weight = 10,
            text = "jade",
        },
        {
            weight = 10,
            text = "turquoise",
        },
        {
            weight = 10,
            text = "lapis lazuli",
        },
        {
            weight = 10,
            text = "glass",
        },
        {
            weight = 2,
            text = "gossamer",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
