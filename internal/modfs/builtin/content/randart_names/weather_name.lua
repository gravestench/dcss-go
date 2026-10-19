-- _weather_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_weather_name_",
    entries = {
        {
            weight = 10,
            text = "Blue Skies",
        },
        {
            weight = 10,
            text = "Boiling Hail",
        },
        {
            weight = 10,
            text = "Chill Winds",
        },
        {
            weight = 10,
            text = "Cloud Cover",
        },
        {
            weight = 10,
            text = "Dust Devil",
        },
        {
            weight = 10,
            text = "Howling Wind",
        },
        {
            weight = 10,
            text = "Lightning Storm",
        },
        {
            weight = 10,
            text = "Perpetual Drought",
        },
        {
            weight = 10,
            text = "Pleasant Breezes",
        },
        {
            weight = 10,
            text = "Quiet Fog",
        },
        {
            weight = 10,
            text = "Soft Rains",
        },
        {
            weight = 10,
            text = "Spring Thaw",
        },
        {
            weight = 10,
            text = "the Blizzard",
        },
        {
            weight = 10,
            text = "the First Snow",
        },
        {
            weight = 10,
            text = "the Hurricane",
        },
        {
            weight = 10,
            text = "the Thunderstorm",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
