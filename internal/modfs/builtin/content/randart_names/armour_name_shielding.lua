-- _armour_name_shielding_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_armour_name_shielding_",
    entries = {
        {
            weight = 10,
            text = "Complete Protection",
        },
        {
            weight = 10,
            text = "Death's Door",
        },
        {
            weight = 10,
            text = "Defence",
        },
        {
            weight = 10,
            text = "Exclusion",
        },
        {
            weight = 10,
            text = "Fortification",
        },
        {
            weight = 10,
            text = "Impermeability",
        },
        {
            weight = 10,
            text = "Inviolability",
        },
        {
            weight = 10,
            text = "Refuge",
        },
        {
            weight = 10,
            text = "Repulsion",
        },
        {
            weight = 10,
            text = "Shielding",
        },
        {
            weight = 10,
            text = "the Armoured One",
        },
        {
            weight = 10,
            text = "the Bulwark",
        },
        {
            weight = 10,
            text = "the Gate",
        },
        {
            weight = 10,
            text = "the Saviour",
        },
        {
            weight = 10,
            text = "the Stone Wall",
        },
        {
            weight = 10,
            text = "the Unbroken",
        },
        {
            weight = 10,
            text = "the Untouchables",
        },
        {
            weight = 10,
            text = "the Ward",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
