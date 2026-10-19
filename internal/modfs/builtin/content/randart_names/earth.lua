-- earth is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "earth",
    entries = {
        {
            weight = 10,
            text = "Bedrock",
        },
        {
            weight = 10,
            text = "Clay",
        },
        {
            weight = 10,
            text = "Earth",
        },
        {
            weight = 10,
            text = "Excavation",
        },
        {
            weight = 10,
            text = "Geology",
        },
        {
            weight = 10,
            text = "Grit",
        },
        {
            weight = 10,
            text = "Metal",
        },
        {
            weight = 10,
            text = "Minerals",
        },
        {
            weight = 10,
            text = "Silt",
        },
        {
            weight = 10,
            text = "Spelunking",
        },
        {
            weight = 10,
            text = "Stones",
        },
        {
            weight = 10,
            text = "Terra Firma",
        },
        {
            weight = 10,
            text = "Terrain",
        },
        {
            weight = 10,
            text = "the Boulder",
        },
        {
            weight = 10,
            text = "the Caves",
        },
        {
            weight = 10,
            text = "the Geologist",
        },
        {
            weight = 10,
            text = "the Ground",
        },
        {
            weight = 10,
            text = "the Lithosphere",
        },
        {
            weight = 10,
            text = "the Mountains",
        },
        {
            weight = 10,
            text = "the Quarry",
        },
        {
            weight = 10,
            text = "the Rocks",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
