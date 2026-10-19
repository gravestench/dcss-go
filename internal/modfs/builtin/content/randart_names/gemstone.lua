-- _gemstone_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_gemstone_",
    entries = {
        {
            weight = 10,
            text = "diamond",
        },
        {
            weight = 10,
            text = "ruby",
        },
        {
            weight = 10,
            text = "jacinth",
        },
        {
            weight = 10,
            text = "sapphire",
        },
        {
            weight = 10,
            text = "black opal",
        },
        {
            weight = 10,
            text = "emerald",
        },
        {
            weight = 10,
            text = "turquoise",
        },
        {
            weight = 10,
            text = "citrine",
        },
        {
            weight = 10,
            text = "aquamarine",
        },
        {
            weight = 10,
            text = "amber",
        },
        {
            weight = 10,
            text = "topaz",
        },
        {
            weight = 10,
            text = "jet",
        },
        {
            weight = 10,
            text = "opal",
        },
        {
            weight = 10,
            text = "garnet",
        },
        {
            weight = 10,
            text = "amethyst",
        },
        {
            weight = 10,
            text = "jasper",
        },
        {
            weight = 10,
            text = "obsidian",
        },
        {
            weight = 10,
            text = "agate",
        },
        {
            weight = 10,
            text = "jade",
        },
        {
            weight = 10,
            text = "pearl",
        },
        {
            weight = 10,
            text = "tiger eye",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
