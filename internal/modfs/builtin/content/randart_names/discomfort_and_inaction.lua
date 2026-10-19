-- _discomfort_and_inaction_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_discomfort_and_inaction_",
    entries = {
        {
            weight = 10,
            text = "Bad Feelings",
        },
        {
            weight = 10,
            text = "Bitterness",
        },
        {
            weight = 10,
            text = "Disappointment",
        },
        {
            weight = 10,
            text = "Entitlement",
        },
        {
            weight = 10,
            text = "Failure",
        },
        {
            weight = 10,
            text = "Insecurity",
        },
        {
            weight = 10,
            text = "Minor Irritation",
        },
        {
            weight = 10,
            text = "Negation",
        },
        {
            weight = 10,
            text = "Servitude",
        },
        {
            weight = 10,
            text = "Submission",
        },
        {
            weight = 10,
            text = "Vexation",
        },
        {
            weight = 10,
            text = "Apathy",
        },
        {
            weight = 10,
            text = "Boredom",
        },
        {
            weight = 10,
            text = "Ennui",
        },
        {
            weight = 10,
            text = "Inaction",
        },
        {
            weight = 10,
            text = "Lethargy",
        },
        {
            weight = 10,
            text = "Lifelessness",
        },
        {
            weight = 10,
            text = "Negligence",
        },
        {
            weight = 10,
            text = "Oblivion",
        },
        {
            weight = 10,
            text = "Omission",
        },
        {
            weight = 10,
            text = "Restlessness",
        },
        {
            weight = 10,
            text = "the Doldrums",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
