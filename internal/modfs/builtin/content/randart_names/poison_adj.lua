-- poison adj is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "poison adj",
    entries = {
        {
            weight = 10,
            text = "Baneful",
        },
        {
            weight = 10,
            text = "Cankerous",
        },
        {
            weight = 10,
            text = "Fetid",
        },
        {
            weight = 10,
            text = "Filthy",
        },
        {
            weight = 10,
            text = "Foul",
        },
        {
            weight = 10,
            text = "Intoxicating",
        },
        {
            weight = 10,
            text = "Nocuous",
        },
        {
            weight = 10,
            text = "Noxious",
        },
        {
            weight = 10,
            text = "Pestilent",
        },
        {
            weight = 10,
            text = "Poisonous",
        },
        {
            weight = 10,
            text = "Putrid",
        },
        {
            weight = 10,
            text = "Rank",
        },
        {
            weight = 10,
            text = "Septic",
        },
        {
            weight = 10,
            text = "Tainted",
        },
        {
            weight = 10,
            text = "Toxic",
        },
        {
            weight = 10,
            text = "Unclean",
        },
        {
            weight = 10,
            text = "Venomous",
        },
        {
            weight = 10,
            text = "Viperous",
        },
        {
            weight = 10,
            text = "Virous",
        },
        {
            weight = 10,
            text = "Virulent",
        },
        {
            weight = 10,
            text = "Vitriolic",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
