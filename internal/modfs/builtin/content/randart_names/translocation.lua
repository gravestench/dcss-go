-- translocation is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "translocation",
    entries = {
        {
            weight = 10,
            text = "Coordinates",
        },
        {
            weight = 10,
            text = "Direction",
        },
        {
            weight = 10,
            text = "Dislocation",
        },
        {
            weight = 10,
            text = "Displacement",
        },
        {
            weight = 10,
            text = "Elsewhere",
        },
        {
            weight = 10,
            text = "Orientation",
        },
        {
            weight = 10,
            text = "Peregrination",
        },
        {
            weight = 10,
            text = "Shifting",
        },
        {
            weight = 10,
            text = "Superposition",
        },
        {
            weight = 10,
            text = "Translocation",
        },
        {
            weight = 10,
            text = "Transposition",
        },
        {
            weight = 10,
            text = "Wanderlust",
        },
        {
            weight = 10,
            text = "the Compass",
        },
        {
            weight = 10,
            text = "the Excursion",
        },
        {
            weight = 10,
            text = "the Jaunt",
        },
        {
            weight = 10,
            text = "the Map",
        },
        {
            weight = 10,
            text = "the Tesseract",
        },
        {
            weight = 10,
            text = "the Traveller",
        },
        {
            weight = 10,
            text = "the Voyage",
        },
        {
            weight = 10,
            text = "the Wayfarer",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
