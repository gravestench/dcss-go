-- air is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "air",
    entries = {
        {
            weight = 10,
            text = "Air",
        },
        {
            weight = 10,
            text = "Breath",
        },
        {
            weight = 10,
            text = "Clouds",
        },
        {
            weight = 10,
            text = "Conduction",
        },
        {
            weight = 10,
            text = "Feathers",
        },
        {
            weight = 10,
            text = "Fog",
        },
        {
            weight = 10,
            text = "Gusts",
        },
        {
            weight = 10,
            text = "Lightning",
        },
        {
            weight = 10,
            text = "Ozone",
        },
        {
            weight = 10,
            text = "Weather",
        },
        {
            weight = 10,
            text = "Vapour",
        },
        {
            weight = 10,
            text = "the Atmosphere",
        },
        {
            weight = 10,
            text = "the Birds",
        },
        {
            weight = 10,
            text = "the Brume",
        },
        {
            weight = 10,
            text = "the Lungs",
        },
        {
            weight = 10,
            text = "the Nimbus",
        },
        {
            weight = 10,
            text = "the Sky",
        },
        {
            weight = 10,
            text = "the Squall",
        },
        {
            weight = 10,
            text = "the Storm",
        },
        {
            weight = 10,
            text = "the Tempest",
        },
        {
            weight = 10,
            text = "the Welkin",
        },
        {
            weight = 10,
            text = "the Wind",
        },
        {
            weight = 10,
            text = "the Zephyr",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
