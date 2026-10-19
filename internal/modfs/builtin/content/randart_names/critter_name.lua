-- _critter_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_critter_name_",
    entries = {
        {
            weight = 10,
            text = "Alphagorgon",
        },
        {
            weight = 10,
            text = "Slorg",
        },
        {
            weight = 10,
            text = "Eight Boll Weevils",
        },
        {
            weight = 10,
            text = "Grue",
        },
        {
            weight = 10,
            text = "Hot Ocelot",
        },
        {
            weight = 10,
            text = "Jabberwock",
        },
        {
            weight = 1,
            text = "Were-rabbit",
        },
        {
            weight = 10,
            text = "Wumpus",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
