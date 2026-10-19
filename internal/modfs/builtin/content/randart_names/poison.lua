-- poison is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "poison",
    entries = {
        {
            weight = 10,
            text = "Blight",
        },
        {
            weight = 10,
            text = "Contamination",
        },
        {
            weight = 10,
            text = "Envenoming",
        },
        {
            weight = 10,
            text = "Filth",
        },
        {
            weight = 10,
            text = "Impurities",
        },
        {
            weight = 10,
            text = "Intoxication",
        },
        {
            weight = 10,
            text = "Pestilence",
        },
        {
            weight = 10,
            text = "Poison",
        },
        {
            weight = 10,
            text = "Poisoning",
        },
        {
            weight = 10,
            text = "Pollution",
        },
        {
            weight = 10,
            text = "Putrescence",
        },
        {
            weight = 10,
            text = "Toxicity",
        },
        {
            weight = 10,
            text = "Toxins",
        },
        {
            weight = 10,
            text = "Venin",
        },
        {
            weight = 10,
            text = "Venom",
        },
        {
            weight = 10,
            text = "Vitiation",
        },
        {
            weight = 10,
            text = "the Assassin",
        },
        {
            weight = 5,
            text = "the Black Widow",
        },
        {
            weight = 1,
            text = "the Coward",
        },
        {
            weight = 1,
            text = "the Gift",
        },
        {
            weight = 10,
            text = "the Snake",
        },
        {
            weight = 10,
            text = "the Spider",
        },
        {
            weight = 10,
            text = "the Stinger",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
