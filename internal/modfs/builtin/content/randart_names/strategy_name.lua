-- _strategy_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_strategy_name_",
    entries = {
        {
            weight = 10,
            text = "Defence",
        },
        {
            weight = 10,
            text = "Defence by Offence",
        },
        {
            weight = 10,
            text = "Expedience",
        },
        {
            weight = 10,
            text = "Guile",
        },
        {
            weight = 10,
            text = "Offence",
        },
        {
            weight = 10,
            text = "Optimality",
        },
        {
            weight = 10,
            text = "Overwhelming Force",
        },
        {
            weight = 10,
            text = "Reinforcement",
        },
        {
            weight = 10,
            text = "Strategic Superiority",
        },
        {
            weight = 10,
            text = "Subterfuge",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
