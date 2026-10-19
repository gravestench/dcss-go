-- _ashenzari_heavens_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_ashenzari_heavens_",
    entries = {
        {
            weight = 10,
            text = "Cosmos",
        },
        {
            weight = 10,
            text = "Empyrean",
        },
        {
            weight = 10,
            text = "Ether",
        },
        {
            weight = 10,
            text = "Firmament",
        },
        {
            weight = 10,
            text = "Heavens",
        },
        {
            weight = 40,
            text = "Sky",
        },
        {
            weight = 10,
            text = "Sphere",
        },
        {
            weight = 10,
            text = "Welkin",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
