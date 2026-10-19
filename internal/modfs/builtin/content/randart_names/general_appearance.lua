-- general appearance is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "general appearance",
    entries = {
        {
            weight = 10,
            text = "brightly glowing",
        },
        {
            weight = 10,
            text = "smoking",
        },
        {
            weight = 10,
            text = "scorched",
        },
        {
            weight = 10,
            text = "twisted",
        },
        {
            weight = 10,
            text = "shimmering",
        },
        {
            weight = 10,
            text = "warped",
        },
        {
            weight = 10,
            text = "transparent",
        },
        {
            weight = 10,
            text = "translucent",
        },
        {
            weight = 10,
            text = "encrusted",
        },
        {
            weight = 10,
            text = "pitted",
        },
        {
            weight = 10,
            text = "slimy",
        },
        {
            weight = 10,
            text = "polished",
        },
        {
            weight = 10,
            text = "fine",
        },
        {
            weight = 10,
            text = "crude",
        },
        {
            weight = 10,
            text = "ancient",
        },
        {
            weight = 10,
            text = "faintly glowing",
        },
        {
            weight = 10,
            text = "steaming",
        },
        {
            weight = 10,
            text = "dazzling",
        },
        {
            weight = 10,
            text = "masterwork",
        },
        {
            weight = 2,
            text = "smouldering",
        },
        {
            weight = 5,
            text = "glimmering",
        },
        {
            weight = 2,
            text = "buzzing",
        },
        {
            weight = 5,
            text = "fading",
        },
        {
            weight = 2,
            text = "blackened",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
