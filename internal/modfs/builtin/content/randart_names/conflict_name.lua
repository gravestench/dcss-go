-- _conflict_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_conflict_name_",
    entries = {
        {
            weight = 10,
            text = "Brawling",
        },
        {
            weight = 10,
            text = "Conflict",
        },
        {
            weight = 10,
            text = "Contention",
        },
        {
            weight = 10,
            text = "Discord",
        },
        {
            weight = 10,
            text = "Dissent",
        },
        {
            weight = 10,
            text = "Division",
        },
        {
            weight = 10,
            text = "Doubt",
        },
        {
            weight = 10,
            text = "Internal Strife",
        },
        {
            weight = 10,
            text = "Melee",
        },
        {
            weight = 10,
            text = "Resumed Hostilities",
        },
        {
            weight = 10,
            text = "Tension",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
