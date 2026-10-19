-- _jewellery appearance_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_jewellery appearance_",
    entries = {
        {
            weight = 10,
            text = "scintillating",
        },
        {
            weight = 10,
            text = "sparkling",
        },
        {
            weight = 10,
            text = "flickering",
        },
        {
            weight = 10,
            text = "glittering",
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
            text = "shimmering",
        },
        {
            weight = 10,
            text = "wavering",
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
            text = "pitted",
        },
        {
            weight = 10,
            text = "slimy",
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
            text = "brightly glowing",
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
            text = "heavily runed",
        },
        {
            weight = 10,
            text = "vibrating",
        },
        {
            weight = 10,
            text = "twitching",
        },
        {
            weight = 10,
            text = "coiled",
        },
        {
            weight = 10,
            text = "bound",
        },
        {
            weight = 10,
            text = "clouded",
        },
        {
            weight = 2,
            text = "serpentine",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
