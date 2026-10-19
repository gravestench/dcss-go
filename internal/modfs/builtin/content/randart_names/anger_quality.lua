-- _anger_quality_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_anger_quality_",
    entries = {
        {
            weight = 10,
            text = "Anger",
        },
        {
            weight = 10,
            text = "Brutal Revenge",
        },
        {
            weight = 10,
            text = "Disproportionate Response",
        },
        {
            weight = 10,
            text = "Fury",
        },
        {
            weight = 10,
            text = "Hatred",
        },
        {
            weight = 10,
            text = "Indignation",
        },
        {
            weight = 10,
            text = "Outrage",
        },
        {
            weight = 10,
            text = "Righteous Anger",
        },
        {
            weight = 10,
            text = "Righteous Fury",
        },
        {
            weight = 10,
            text = "Scorn",
        },
        {
            weight = 10,
            text = "Vengeance",
        },
        {
            weight = 10,
            text = "Wrath",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
