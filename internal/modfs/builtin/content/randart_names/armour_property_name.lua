-- _armour_property_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_armour_property_name_",
    entries = {
        {
            weight = 10,
            text = "Death Resistance",
        },
        {
            weight = 10,
            text = "Disguise",
        },
        {
            weight = 10,
            text = "Fashionability",
        },
        {
            weight = 10,
            text = "Grace",
        },
        {
            weight = 10,
            text = "Gravitas",
        },
        {
            weight = 10,
            text = "Impressiveness",
        },
        {
            weight = 10,
            text = "Least Resistance",
        },
        {
            weight = 10,
            text = "Polish",
        },
        {
            weight = 10,
            text = "Privacy",
        },
        {
            weight = 10,
            text = "Protective Custody",
        },
        {
            weight = 10,
            text = "Resilience",
        },
        {
            weight = 10,
            text = "Resonance",
        },
        {
            weight = 10,
            text = "Shadows and Fog",
        },
        {
            weight = 10,
            text = "Supple Strength",
        },
        {
            weight = 10,
            text = "Weightlessness",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
