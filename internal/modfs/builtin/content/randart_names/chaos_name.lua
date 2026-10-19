-- _chaos_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_chaos_name_",
    entries = {
        {
            weight = 10,
            text = "Ambiguity",
        },
        {
            weight = 10,
            text = "Arbitration",
        },
        {
            weight = 10,
            text = "Calamity",
        },
        {
            weight = 10,
            text = "Chance",
        },
        {
            weight = 10,
            text = "Change",
        },
        {
            weight = 10,
            text = "Chaos",
        },
        {
            weight = 10,
            text = "Constant Reorganisation",
        },
        {
            weight = 10,
            text = "Contradiction",
        },
        {
            weight = 10,
            text = "Disarray",
        },
        {
            weight = 10,
            text = "Disaster",
        },
        {
            weight = 10,
            text = "Disharmony",
        },
        {
            weight = 10,
            text = "Disintegration",
        },
        {
            weight = 10,
            text = "Disorder",
        },
        {
            weight = 10,
            text = "Dissolution",
        },
        {
            weight = 10,
            text = "Distraction",
        },
        {
            weight = 10,
            text = "Extremism",
        },
        {
            weight = 10,
            text = "Havoc",
        },
        {
            weight = 10,
            text = "Imbalance",
        },
        {
            weight = 10,
            text = "Impermanence",
        },
        {
            weight = 10,
            text = "Incongruity",
        },
        {
            weight = 10,
            text = "Mayhem",
        },
        {
            weight = 10,
            text = "Revolt",
        },
        {
            weight = 10,
            text = "Tumult",
        },
        {
            weight = 10,
            text = "Turmoil",
        },
        {
            weight = 10,
            text = "Upheaval",
        },
        {
            weight = 10,
            text = "the Extremes",
        },
        {
            weight = 10,
            text = "the Fray",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
