-- _sky_or_light_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_sky_or_light_",
    entries = {
        {
            weight = 10,
            text = "Darkness",
        },
        {
            weight = 10,
            text = "Dim Light",
        },
        {
            weight = 10,
            text = "Light",
        },
        {
            weight = 10,
            text = "Starshine",
        },
        {
            weight = 10,
            text = "Sunlight",
        },
        {
            weight = 10,
            text = "the Endless Expanse",
        },
        {
            weight = 10,
            text = "the Gloaming",
        },
        {
            weight = 10,
            text = "the Heavens",
        },
        {
            weight = 10,
            text = "the Moon",
        },
        {
            weight = 10,
            text = "the Shining Light",
        },
        {
            weight = 10,
            text = "the Skies Above",
        },
        {
            weight = 10,
            text = "the Sky",
        },
        {
            weight = 10,
            text = "the Sun",
        },
        {
            weight = 10,
            text = "the @_sky_colour_name_@ Skies",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
