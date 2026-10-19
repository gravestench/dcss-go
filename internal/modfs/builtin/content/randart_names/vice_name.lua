-- _vice_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_vice_name_",
    entries = {
        {
            weight = 10,
            text = "Gluttony",
        },
        {
            weight = 10,
            text = "Greed",
        },
        {
            weight = 10,
            text = "Lust",
        },
        {
            weight = 10,
            text = "Pride",
        },
        {
            weight = 10,
            text = "Sloth",
        },
        {
            weight = 10,
            text = "Vanity",
        },
        {
            weight = 10,
            text = "Amorality",
        },
        {
            weight = 10,
            text = "Cowardice",
        },
        {
            weight = 10,
            text = "Dishonesty",
        },
        {
            weight = 10,
            text = "Dishonour",
        },
        {
            weight = 10,
            text = "Foolhardiness",
        },
        {
            weight = 10,
            text = "Immorality",
        },
        {
            weight = 10,
            text = "Impatience",
        },
        {
            weight = 10,
            text = "Lies",
        },
        {
            weight = 10,
            text = "Moral Flaws",
        },
        {
            weight = 10,
            text = "Past Mistakes",
        },
        {
            weight = 10,
            text = "Recklessness",
        },
        {
            weight = 10,
            text = "Sin",
        },
        {
            weight = 10,
            text = "Spite",
        },
        {
            weight = 10,
            text = "Untruth",
        },
        {
            weight = 10,
            text = "Youthful Indiscretion",
        },
        {
            weight = 10,
            text = "the Original Sin",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
