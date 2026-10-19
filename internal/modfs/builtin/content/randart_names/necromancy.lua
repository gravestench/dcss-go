-- necromancy is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "necromancy",
    entries = {
        {
            weight = 10,
            text = "Darkness",
        },
        {
            weight = 10,
            text = "Death",
        },
        {
            weight = 5,
            text = "Diablerie",
        },
        {
            weight = 10,
            text = "Evil",
        },
        {
            weight = 10,
            text = "Exhumation",
        },
        {
            weight = 10,
            text = "Gloom",
        },
        {
            weight = 10,
            text = "Misery",
        },
        {
            weight = 10,
            text = "Mortification",
        },
        {
            weight = 10,
            text = "Necromancy",
        },
        {
            weight = 10,
            text = "Shadows",
        },
        {
            weight = 10,
            text = "Stolen Souls",
        },
        {
            weight = 10,
            text = "the Crypt",
        },
        {
            weight = 10,
            text = "the Dead",
        },
        {
            weight = 10,
            text = "the Grave",
        },
        {
            weight = 10,
            text = "the Mausoleum",
        },
        {
            weight = 10,
            text = "the Mortuary",
        },
        {
            weight = 10,
            text = "the Undead",
        },
        {
            weight = 150,
            text = "@_Evil_adjective_@ @_Evil_noun_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
