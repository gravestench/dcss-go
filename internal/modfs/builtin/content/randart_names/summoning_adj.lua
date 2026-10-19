-- summoning adj is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "summoning adj",
    entries = {
        {
            weight = 10,
            text = "Allied",
        },
        {
            weight = 10,
            text = "Amassed",
        },
        {
            weight = 10,
            text = "Assembled",
        },
        {
            weight = 10,
            text = "Assistive",
        },
        {
            weight = 10,
            text = "Called",
        },
        {
            weight = 10,
            text = "Collective",
        },
        {
            weight = 10,
            text = "Congregated",
        },
        {
            weight = 10,
            text = "Creative",
        },
        {
            weight = 10,
            text = "Friendly",
        },
        {
            weight = 10,
            text = "Gathered",
        },
        {
            weight = 10,
            text = "Generative",
        },
        {
            weight = 10,
            text = "Helpful",
        },
        {
            weight = 10,
            text = "Productive",
        },
        {
            weight = 10,
            text = "Summoned",
        },
        {
            weight = 10,
            text = "Supportive",
        },
        {
            weight = 10,
            text = "Unified",
        },
        {
            weight = 10,
            text = "United",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
