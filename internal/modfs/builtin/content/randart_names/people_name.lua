-- _people_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_people_name_",
    entries = {
        {
            weight = 10,
            text = "Ancients",
        },
        {
            weight = 10,
            text = "Coward",
        },
        {
            weight = 10,
            text = "Enemy",
        },
        {
            weight = 10,
            text = "Fool",
        },
        {
            weight = 10,
            text = "Genius",
        },
        {
            weight = 10,
            text = "Hero",
        },
        {
            weight = 10,
            text = "Jester",
        },
        {
            weight = 10,
            text = "King",
        },
        {
            weight = 10,
            text = "Madman",
        },
        {
            weight = 10,
            text = "Messenger",
        },
        {
            weight = 10,
            text = "Pariah",
        },
        {
            weight = 10,
            text = "Philosopher",
        },
        {
            weight = 10,
            text = "Priest",
        },
        {
            weight = 10,
            text = "Queen",
        },
        {
            weight = 10,
            text = "Saviour",
        },
        {
            weight = 10,
            text = "Scavenger",
        },
        {
            weight = 10,
            text = "Traitor",
        },
        {
            weight = 15,
            text = "@_diviner_name_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
