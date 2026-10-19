-- _mental_illness_armour_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_mental_illness_armour_",
    entries = {
        {
            weight = 10,
            text = "Agoraphobia",
        },
        {
            weight = 10,
            text = "Catatonia",
        },
        {
            weight = 10,
            text = "Claustrophobia",
        },
        {
            weight = 10,
            text = "Depression",
        },
        {
            weight = 10,
            text = "Dyspraxia",
        },
        {
            weight = 10,
            text = "Hysteria",
        },
        {
            weight = 10,
            text = "Kleptomania",
        },
        {
            weight = 10,
            text = "Masochism",
        },
        {
            weight = 10,
            text = "Melancholy",
        },
        {
            weight = 10,
            text = "Mental Paralysis",
        },
        {
            weight = 10,
            text = "Narcissism",
        },
        {
            weight = 10,
            text = "Paranoia",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
