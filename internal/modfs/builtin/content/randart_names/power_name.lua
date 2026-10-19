-- _power_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_power_name_",
    entries = {
        {
            weight = 10,
            text = "Big Damage",
        },
        {
            weight = 10,
            text = "Dominance",
        },
        {
            weight = 10,
            text = "Domination",
        },
        {
            weight = 10,
            text = "Glory",
        },
        {
            weight = 10,
            text = "Grandeur",
        },
        {
            weight = 10,
            text = "Hubris",
        },
        {
            weight = 10,
            text = "Intimidation",
        },
        {
            weight = 10,
            text = "Invincibility",
        },
        {
            weight = 10,
            text = "Magnificence",
        },
        {
            weight = 10,
            text = "Mastery",
        },
        {
            weight = 10,
            text = "Might",
        },
        {
            weight = 10,
            text = "Success",
        },
        {
            weight = 10,
            text = "Superiority",
        },
        {
            weight = 10,
            text = "Triumph",
        },
        {
            weight = 10,
            text = "Victory",
        },
        {
            weight = 10,
            text = "Wondrous Power",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
