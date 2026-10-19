-- conjuration is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "conjuration",
    entries = {
        {
            weight = 10,
            text = "Arcane Weapons",
        },
        {
            weight = 10,
            text = "Attacks",
        },
        {
            weight = 10,
            text = "Battle Magic",
        },
        {
            weight = 10,
            text = "Battling",
        },
        {
            weight = 10,
            text = "Blasting",
        },
        {
            weight = 10,
            text = "Blasts",
        },
        {
            weight = 10,
            text = "Blows and Bruises",
        },
        {
            weight = 10,
            text = "Bolts",
        },
        {
            weight = 10,
            text = "Combat Magic",
        },
        {
            weight = 10,
            text = "Concussion",
        },
        {
            weight = 10,
            text = "Conjuration",
        },
        {
            weight = 5,
            text = "Conjuring",
        },
        {
            weight = 5,
            text = "Conjury",
        },
        {
            weight = 10,
            text = "Conflict",
        },
        {
            weight = 10,
            text = "Confrontation",
        },
        {
            weight = 10,
            text = "Damage Dealing",
        },
        {
            weight = 10,
            text = "Hurting",
        },
        {
            weight = 10,
            text = "Outbursts",
        },
        {
            weight = 10,
            text = "Striking",
        },
        {
            weight = 1,
            text = "Traumaturgy",
        },
        {
            weight = 10,
            text = "the Barrage",
        },
        {
            weight = 1,
            text = "the Fifth Circle",
        },
        {
            weight = 10,
            text = "the Impact",
        },
        {
            weight = 10,
            text = "the Salvo",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
