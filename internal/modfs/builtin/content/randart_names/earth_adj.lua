-- earth adj is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "earth adj",
    entries = {
        {
            weight = 10,
            text = "Arenous",
        },
        {
            weight = 10,
            text = "Ashen",
        },
        {
            weight = 10,
            text = "Chthonic",
        },
        {
            weight = 10,
            text = "Coarse",
        },
        {
            weight = 10,
            text = "Crystalline",
        },
        {
            weight = 10,
            text = "Dusty",
        },
        {
            weight = 10,
            text = "Earthen",
        },
        {
            weight = 10,
            text = "Flinty",
        },
        {
            weight = 10,
            text = "Geological",
        },
        {
            weight = 10,
            text = "Gritty",
        },
        {
            weight = 10,
            text = "Grounded",
        },
        {
            weight = 10,
            text = "Iron",
        },
        {
            weight = 10,
            text = "Lithic",
        },
        {
            weight = 10,
            text = "Metallic",
        },
        {
            weight = 10,
            text = "Petrified",
        },
        {
            weight = 10,
            text = "Petrous",
        },
        {
            weight = 10,
            text = "Rocky",
        },
        {
            weight = 10,
            text = "Sandy",
        },
        {
            weight = 10,
            text = "Solid",
        },
        {
            weight = 10,
            text = "Stony",
        },
        {
            weight = 10,
            text = "Telluric",
        },
        {
            weight = 10,
            text = "Terrestrial",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
