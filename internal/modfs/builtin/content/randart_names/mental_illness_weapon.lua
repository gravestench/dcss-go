-- _mental_illness_weapon_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_mental_illness_weapon_",
    entries = {
        {
            weight = 10,
            text = "Compulsion",
        },
        {
            weight = 10,
            text = "Egomania",
        },
        {
            weight = 10,
            text = "Exhibitionism",
        },
        {
            weight = 10,
            text = "Fatigue",
        },
        {
            weight = 10,
            text = "Fixation",
        },
        {
            weight = 10,
            text = "Insomnia",
        },
        {
            weight = 10,
            text = "Megalomania",
        },
        {
            weight = 10,
            text = "Neurosis",
        },
        {
            weight = 10,
            text = "Obsession",
        },
        {
            weight = 10,
            text = "Oenomania",
        },
        {
            weight = 10,
            text = "Perfectionism",
        },
        {
            weight = 10,
            text = "Psychosis",
        },
        {
            weight = 10,
            text = "Pyromania",
        },
        {
            weight = 10,
            text = "Satyriasis",
        },
        {
            weight = 10,
            text = "Suicidal Tendencies",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
