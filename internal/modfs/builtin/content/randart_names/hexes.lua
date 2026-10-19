-- hexes is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "hexes",
    entries = {
        {
            weight = 10,
            text = "Beguiling",
        },
        {
            weight = 10,
            text = "Bewitchment",
        },
        {
            weight = 10,
            text = "Charms",
        },
        {
            weight = 10,
            text = "Curses",
        },
        {
            weight = 10,
            text = "Enchantment",
        },
        {
            weight = 10,
            text = "Ensorcelling",
        },
        {
            weight = 10,
            text = "Execration",
        },
        {
            weight = 10,
            text = "Fascination",
        },
        {
            weight = 10,
            text = "Glamour",
        },
        {
            weight = 10,
            text = "Guile",
        },
        {
            weight = 10,
            text = "Hexes",
        },
        {
            weight = 5,
            text = "Hexing",
        },
        {
            weight = 10,
            text = "Imprecation",
        },
        {
            weight = 10,
            text = "Interference",
        },
        {
            weight = 10,
            text = "Jinxing",
        },
        {
            weight = 10,
            text = "Malediction",
        },
        {
            weight = 10,
            text = "Spellbinding",
        },
        {
            weight = 10,
            text = "the Oath",
        },
        {
            weight = 1,
            text = "the Whammy",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
