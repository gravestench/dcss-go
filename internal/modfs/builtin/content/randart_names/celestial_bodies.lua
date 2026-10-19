-- _celestial_bodies_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_celestial_bodies_",
    entries = {
        {
            weight = 5,
            text = "Blue Moon",
        },
        {
            weight = 10,
            text = "Comet",
        },
        {
            weight = 10,
            text = "Constellations",
        },
        {
            weight = 10,
            text = "Evening Star",
        },
        {
            weight = 5,
            text = "Harvest Moon",
        },
        {
            weight = 5,
            text = "Midnight Sun",
        },
        {
            weight = 10,
            text = "Moon",
        },
        {
            weight = 10,
            text = "Morning Star",
        },
        {
            weight = 10,
            text = "Northern Lights",
        },
        {
            weight = 10,
            text = "Planets",
        },
        {
            weight = 10,
            text = "Pleiades",
        },
        {
            weight = 10,
            text = "Stars",
        },
        {
            weight = 10,
            text = "Sun",
        },
        {
            weight = 10,
            text = "Black Moon",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
