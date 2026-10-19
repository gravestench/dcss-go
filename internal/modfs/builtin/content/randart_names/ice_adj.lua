-- ice adj is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "ice adj",
    entries = {
        {
            weight = 10,
            text = "Algid",
        },
        {
            weight = 10,
            text = "Boreal",
        },
        {
            weight = 10,
            text = "Chilled",
        },
        {
            weight = 10,
            text = "Chilling",
        },
        {
            weight = 10,
            text = "Congealing",
        },
        {
            weight = 10,
            text = "Freezing",
        },
        {
            weight = 10,
            text = "Frigid",
        },
        {
            weight = 10,
            text = "Frigorific",
        },
        {
            weight = 10,
            text = "Frore",
        },
        {
            weight = 10,
            text = "Frostbitten",
        },
        {
            weight = 10,
            text = "Frosty",
        },
        {
            weight = 10,
            text = "Frozen",
        },
        {
            weight = 10,
            text = "Gelid",
        },
        {
            weight = 10,
            text = "Glacial",
        },
        {
            weight = 10,
            text = "Hiemal",
        },
        {
            weight = 10,
            text = "Icy",
        },
        {
            weight = 10,
            text = "Numb",
        },
        {
            weight = 10,
            text = "Polar",
        },
        {
            weight = 10,
            text = "Shivering",
        },
        {
            weight = 10,
            text = "Snowy",
        },
        {
            weight = 10,
            text = "Wintry",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
