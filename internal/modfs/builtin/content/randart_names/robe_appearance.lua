-- robe appearance is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "robe appearance",
    entries = {
        {
            weight = 10,
            text = "fabulously ornate",
        },
        {
            weight = 10,
            text = "dull",
        },
        {
            weight = 10,
            text = "sheer",
        },
        {
            weight = 10,
            text = "thick",
        },
        {
            weight = 10,
            text = "heavy",
        },
        {
            weight = 10,
            text = "wizard",
        },
        {
            weight = 10,
            text = "ominously black",
        },
        {
            weight = 10,
            text = "brightly glowing",
        },
        {
            weight = 10,
            text = "smoking",
        },
        {
            weight = 10,
            text = "twisted",
        },
        {
            weight = 10,
            text = "shimmering",
        },
        {
            weight = 10,
            text = "warped",
        },
        {
            weight = 10,
            text = "transparent",
        },
        {
            weight = 10,
            text = "slimy",
        },
        {
            weight = 10,
            text = "fine",
        },
        {
            weight = 10,
            text = "crude",
        },
        {
            weight = 10,
            text = "ripped",
        },
        {
            weight = 10,
            text = "colourful",
        },
        {
            weight = 10,
            text = "creamy pearl",
        },
        {
            weight = 10,
            text = "opalescent",
        },
        {
            weight = 10,
            text = "ancient",
        },
        {
            weight = 10,
            text = "faintly glowing",
        },
        {
            weight = 10,
            text = "steaming",
        },
        {
            weight = 10,
            text = "faintly humming",
        },
        {
            weight = 10,
            text = "bloodstained",
        },
        {
            weight = 10,
            text = "heavily jewelled",
        },
        {
            weight = 10,
            text = "ichor-stained",
        },
        {
            weight = 10,
            text = "distressingly furry",
        },
        {
            weight = 10,
            text = "tattered",
        },
        {
            weight = 10,
            text = "silken",
        },
        {
            weight = 10,
            text = "shadowed",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
