-- _anger_possessive_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_anger_possessive_",
    entries = {
        {
            weight = 10,
            text = "the Extremely Mad",
        },
        {
            weight = 10,
            text = "the Absolute Madman",
        },
        {
            weight = 10,
            text = "the Incandescent",
        },
        {
            weight = 10,
            text = "the Furious",
        },
        {
            weight = 10,
            text = "the Howling One",
        },
        {
            weight = 10,
            text = "the Gibberer",
        },
        {
            weight = 10,
            text = "the Hated",
        },
        {
            weight = 10,
            text = "the Scorned",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
