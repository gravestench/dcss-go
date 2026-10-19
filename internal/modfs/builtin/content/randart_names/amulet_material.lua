-- _amulet material_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_amulet material_",
    entries = {
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
            text = "graven",
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
            text = "zirconium",
        },
        {
            weight = 10,
            text = "sapphire",
        },
        {
            weight = 10,
            text = "emerald",
        },
        {
            weight = 10,
            text = "garnet",
        },
        {
            weight = 10,
            text = "ruby",
        },
        {
            weight = 10,
            text = "jade",
        },
        {
            weight = 10,
            text = "ruby",
        },
        {
            weight = 10,
            text = "crystal",
        },
        {
            weight = 10,
            text = "diamond",
        },
        {
            weight = 10,
            text = "amethyst",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
