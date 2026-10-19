-- other_weapon_name is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "other_weapon_name",
    entries = {
        {
            weight = 10,
            text = "Broken Luck",
        },
        {
            weight = 10,
            text = "Butchery",
        },
        {
            weight = 10,
            text = "Checkmate",
        },
        {
            weight = 10,
            text = "Conversion",
        },
        {
            weight = 10,
            text = "Crawling",
        },
        {
            weight = 10,
            text = "Desertification",
        },
        {
            weight = 10,
            text = "Doors",
        },
        {
            weight = 10,
            text = "Entrepreneurial Spirit",
        },
        {
            weight = 10,
            text = "False Hope",
        },
        {
            weight = 10,
            text = "Gin and Tonic",
        },
        {
            weight = 10,
            text = "Grontol",
        },
        {
            weight = 10,
            text = "Hard Scrabble",
        },
        {
            weight = 10,
            text = "Interdependent Arising",
        },
        {
            weight = 10,
            text = "Irrepressible Laughter",
        },
        {
            weight = 10,
            text = "No Interval",
        },
        {
            weight = 10,
            text = "Prescription",
        },
        {
            weight = 10,
            text = "Red Wine",
        },
        {
            weight = 10,
            text = "Res Nullius",
        },
        {
            weight = 10,
            text = "Spontaneous Combustion",
        },
        {
            weight = 10,
            text = "Terra Nullius",
        },
        {
            weight = 10,
            text = "Traps",
        },
        {
            weight = 10,
            text = "Undoing",
        },
        {
            weight = 10,
            text = "Vodka",
        },
        {
            weight = 10,
            text = "the Blind Eye",
        },
        {
            weight = 10,
            text = "the Briny Deep",
        },
        {
            weight = 10,
            text = "the Empty Page",
        },
        {
            weight = 10,
            text = "the Final Chapter",
        },
        {
            weight = 10,
            text = "the Omega Point",
        },
        {
            weight = 10,
            text = "the Open Hand",
        },
        {
            weight = 10,
            text = "the Pharaoh's Fist",
        },
        {
            weight = 10,
            text = "the Real Monster",
        },
        {
            weight = 10,
            text = "the Spinneret",
        },
        {
            weight = 10,
            text = "the Two Names",
        },
        {
            weight = 10,
            text = "the Unkillable",
        },
        {
            weight = 10,
            text = "the Vendetta",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
