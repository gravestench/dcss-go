-- _card_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_card_",
    entries = {
        {
            weight = 10,
            text = "Two",
        },
        {
            weight = 10,
            text = "Three",
        },
        {
            weight = 10,
            text = "Four",
        },
        {
            weight = 10,
            text = "Five",
        },
        {
            weight = 10,
            text = "Six",
        },
        {
            weight = 10,
            text = "Seven",
        },
        {
            weight = 10,
            text = "Eight",
        },
        {
            weight = 10,
            text = "Nine",
        },
        {
            weight = 10,
            text = "Ten",
        },
        {
            weight = 10,
            text = "Page",
        },
        {
            weight = 10,
            text = "Knight",
        },
        {
            weight = 10,
            text = "Queen",
        },
        {
            weight = 10,
            text = "King",
        },
        {
            weight = 10,
            text = "Ace",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
