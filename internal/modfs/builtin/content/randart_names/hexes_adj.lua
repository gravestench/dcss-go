-- hexes adj is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "hexes adj",
    entries = {
        {
            weight = 10,
            text = "Alluring",
        },
        {
            weight = 10,
            text = "Baleful",
        },
        {
            weight = 10,
            text = "Bewitching",
        },
        {
            weight = 10,
            text = "Captivating",
        },
        {
            weight = 10,
            text = "Charming",
        },
        {
            weight = 10,
            text = "Cunning",
        },
        {
            weight = 10,
            text = "Cursed",
        },
        {
            weight = 10,
            text = "Enchanting",
        },
        {
            weight = 10,
            text = "Ensnaring",
        },
        {
            weight = 10,
            text = "Enthralling",
        },
        {
            weight = 10,
            text = "Entrancing",
        },
        {
            weight = 10,
            text = "Fetching",
        },
        {
            weight = 10,
            text = "Fey",
        },
        {
            weight = 10,
            text = "Hindering",
        },
        {
            weight = 10,
            text = "Maledictive",
        },
        {
            weight = 10,
            text = "Spellbinding",
        },
        {
            weight = 10,
            text = "Vexing",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
