-- _virtue_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_virtue_name_",
    entries = {
        {
            weight = 10,
            text = "Benevolence",
        },
        {
            weight = 10,
            text = "Charity",
        },
        {
            weight = 10,
            text = "Compassion",
        },
        {
            weight = 10,
            text = "Devotion",
        },
        {
            weight = 10,
            text = "Discretion",
        },
        {
            weight = 10,
            text = "Generosity",
        },
        {
            weight = 10,
            text = "Generosity",
        },
        {
            weight = 10,
            text = "Grace",
        },
        {
            weight = 10,
            text = "Honesty",
        },
        {
            weight = 10,
            text = "Hospitality",
        },
        {
            weight = 10,
            text = "Kindness",
        },
        {
            weight = 10,
            text = "Modesty",
        },
        {
            weight = 10,
            text = "Patience",
        },
        {
            weight = 10,
            text = "Temperance",
        },
        {
            weight = 10,
            text = "Thoughtfulness",
        },
        {
            weight = 10,
            text = "Truth",
        },
        {
            weight = 10,
            text = "Understanding",
        },
        {
            weight = 10,
            text = "Virtue",
        },
        {
            weight = 10,
            text = "Wariness",
        },
        {
            weight = 10,
            text = "Wisdom",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
