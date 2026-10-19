-- _book_adjective_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_book_adjective_",
    entries = {
        {
            weight = 10,
            text = "ancient",
        },
        {
            weight = 10,
            text = "antique",
        },
        {
            weight = 10,
            text = "black",
        },
        {
            weight = 10,
            text = "blackened",
        },
        {
            weight = 10,
            text = "colourful",
        },
        {
            weight = 10,
            text = "conspicuous",
        },
        {
            weight = 10,
            text = "curling",
        },
        {
            weight = 10,
            text = "decrepit",
        },
        {
            weight = 10,
            text = "disorganized",
        },
        {
            weight = 10,
            text = "dog-eared",
        },
        {
            weight = 10,
            text = "droning",
        },
        {
            weight = 10,
            text = "embossed",
        },
        {
            weight = 10,
            text = "engraved",
        },
        {
            weight = 10,
            text = "exquisite",
        },
        {
            weight = 10,
            text = "foxed",
        },
        {
            weight = 10,
            text = "fuliginous",
        },
        {
            weight = 10,
            text = "fusty",
        },
        {
            weight = 10,
            text = "glistering",
        },
        {
            weight = 10,
            text = "graven",
        },
        {
            weight = 10,
            text = "grimy",
        },
        {
            weight = 10,
            text = "humming",
        },
        {
            weight = 10,
            text = "inconspicuous",
        },
        {
            weight = 10,
            text = "innocuous",
        },
        {
            weight = 10,
            text = "levitating",
        },
        {
            weight = 10,
            text = "lithographed",
        },
        {
            weight = 10,
            text = "loosely-bound",
        },
        {
            weight = 10,
            text = "quavering",
        },
        {
            weight = 10,
            text = "rare",
        },
        {
            weight = 10,
            text = "shiny",
        },
        {
            weight = 10,
            text = "sooty",
        },
        {
            weight = 10,
            text = "sparkling",
        },
        {
            weight = 10,
            text = "strange",
        },
        {
            weight = 10,
            text = "torn",
        },
        {
            weight = 10,
            text = "well-preserved",
        },
        {
            weight = 10,
            text = "yellowed",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
