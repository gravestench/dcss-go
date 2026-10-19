-- _valour_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_valour_name_",
    entries = {
        {
            weight = 10,
            text = "Action",
        },
        {
            weight = 10,
            text = "Conscience",
        },
        {
            weight = 10,
            text = "Courage",
        },
        {
            weight = 10,
            text = "Defiance",
        },
        {
            weight = 10,
            text = "Duty",
        },
        {
            weight = 10,
            text = "Eternal Vigilance",
        },
        {
            weight = 10,
            text = "Fortitude",
        },
        {
            weight = 10,
            text = "Gallantry",
        },
        {
            weight = 10,
            text = "Honour",
        },
        {
            weight = 10,
            text = "Indomitability",
        },
        {
            weight = 10,
            text = "Integrity",
        },
        {
            weight = 10,
            text = "Prudence",
        },
        {
            weight = 10,
            text = "Purpose",
        },
        {
            weight = 10,
            text = "Resourcefulness",
        },
        {
            weight = 10,
            text = "Responsibility",
        },
        {
            weight = 10,
            text = "Tenacity",
        },
        {
            weight = 10,
            text = "True Grit",
        },
        {
            weight = 10,
            text = "Valiance",
        },
        {
            weight = 10,
            text = "Valour",
        },
        {
            weight = 10,
            text = "Watchfulness",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
