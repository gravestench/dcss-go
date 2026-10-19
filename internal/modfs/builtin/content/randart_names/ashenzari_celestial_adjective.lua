-- _ashenzari_celestial_adjective_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_ashenzari_celestial_adjective_",
    entries = {
        {
            weight = 10,
            text = "Astral",
        },
        {
            weight = 10,
            text = "Celestial",
        },
        {
            weight = 10,
            text = "Cosmic",
        },
        {
            weight = 10,
            text = "Distant",
        },
        {
            weight = 10,
            text = "Elysian",
        },
        {
            weight = 10,
            text = "Sidereal",
        },
        {
            weight = 10,
            text = "Stellar",
        },
        {
            weight = 10,
            text = "Sublime",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
