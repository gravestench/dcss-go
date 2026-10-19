-- ice is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "ice",
    entries = {
        {
            weight = 10,
            text = "Cold",
        },
        {
            weight = 10,
            text = "Congelation",
        },
        {
            weight = 10,
            text = "Firn",
        },
        {
            weight = 10,
            text = "Frostbite",
        },
        {
            weight = 10,
            text = "Glaciation",
        },
        {
            weight = 10,
            text = "Graupel",
        },
        {
            weight = 10,
            text = "Hoarfrost",
        },
        {
            weight = 10,
            text = "Hypothermia",
        },
        {
            weight = 10,
            text = "Ice",
        },
        {
            weight = 10,
            text = "Rime",
        },
        {
            weight = 10,
            text = "Snow",
        },
        {
            weight = 10,
            text = "the Blizzard",
        },
        {
            weight = 10,
            text = "the Chill",
        },
        {
            weight = 10,
            text = "the Glacier",
        },
        {
            weight = 10,
            text = "the Iceberg",
        },
        {
            weight = 10,
            text = "the Snowflakes",
        },
        {
            weight = 10,
            text = "the Winter",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
