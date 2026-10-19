-- fire is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "fire",
    entries = {
        {
            weight = 10,
            text = "Calefaction",
        },
        {
            weight = 10,
            text = "Combustion",
        },
        {
            weight = 10,
            text = "Conflagration",
        },
        {
            weight = 10,
            text = "Embers",
        },
        {
            weight = 10,
            text = "Fire",
        },
        {
            weight = 10,
            text = "Flames",
        },
        {
            weight = 10,
            text = "Heat",
        },
        {
            weight = 10,
            text = "Ignition",
        },
        {
            weight = 10,
            text = "Incandescence",
        },
        {
            weight = 10,
            text = "Kindling",
        },
        {
            weight = 10,
            text = "Pyromania",
        },
        {
            weight = 1,
            text = "Thermatology",
        },
        {
            weight = 10,
            text = "the Arsonist",
        },
        {
            weight = 10,
            text = "the Blaze",
        },
        {
            weight = 10,
            text = "the Coals",
        },
        {
            weight = 10,
            text = "the Inferno",
        },
        {
            weight = 10,
            text = "the Pyre",
        },
        {
            weight = 10,
            text = "the Pyromaniac",
        },
        {
            weight = 10,
            text = "the Summer",
        },
        {
            weight = 10,
            text = "the Volcanoes",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
