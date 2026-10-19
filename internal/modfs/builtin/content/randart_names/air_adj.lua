-- air adj is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "air adj",
    entries = {
        {
            weight = 10,
            text = "Airy",
        },
        {
            weight = 10,
            text = "Aerial",
        },
        {
            weight = 10,
            text = "Atmospheric",
        },
        {
            weight = 10,
            text = "Breezy",
        },
        {
            weight = 10,
            text = "Charged",
        },
        {
            weight = 10,
            text = "Cloudy",
        },
        {
            weight = 10,
            text = "Electric",
        },
        {
            weight = 10,
            text = "Feathery",
        },
        {
            weight = 10,
            text = "Floating",
        },
        {
            weight = 5,
            text = "Fulgurant",
        },
        {
            weight = 5,
            text = "Fulgurous",
        },
        {
            weight = 10,
            text = "Gusty",
        },
        {
            weight = 10,
            text = "Hazy",
        },
        {
            weight = 10,
            text = "Overcast",
        },
        {
            weight = 10,
            text = "Lofty",
        },
        {
            weight = 10,
            text = "Meteoric",
        },
        {
            weight = 10,
            text = "Shocking",
        },
        {
            weight = 10,
            text = "Stormy",
        },
        {
            weight = 10,
            text = "Turbulent",
        },
        {
            weight = 10,
            text = "Vapourous",
        },
        {
            weight = 10,
            text = "Voltaic",
        },
        {
            weight = 10,
            text = "Windy",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
