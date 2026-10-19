-- _good_or_divine_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_good_or_divine_",
    entries = {
        {
            weight = 10,
            text = "Amelioration",
        },
        {
            weight = 10,
            text = "Awe",
        },
        {
            weight = 10,
            text = "Beauty",
        },
        {
            weight = 10,
            text = "Birdsong",
        },
        {
            weight = 10,
            text = "Brilliance",
        },
        {
            weight = 10,
            text = "Contentment",
        },
        {
            weight = 10,
            text = "Creativity",
        },
        {
            weight = 10,
            text = "Curiosity",
        },
        {
            weight = 10,
            text = "Freedom",
        },
        {
            weight = 10,
            text = "Fun",
        },
        {
            weight = 10,
            text = "Happiness",
        },
        {
            weight = 10,
            text = "Joy",
        },
        {
            weight = 10,
            text = "Knowledge",
        },
        {
            weight = 10,
            text = "Leaves",
        },
        {
            weight = 10,
            text = "Liberty",
        },
        {
            weight = 10,
            text = "Life",
        },
        {
            weight = 10,
            text = "Lucidity",
        },
        {
            weight = 10,
            text = "Mirth",
        },
        {
            weight = 10,
            text = "Music",
        },
        {
            weight = 10,
            text = "New Discoveries",
        },
        {
            weight = 10,
            text = "Satisfaction",
        },
        {
            weight = 10,
            text = "Surprise",
        },
        {
            weight = 10,
            text = "Tender Moments",
        },
        {
            weight = 10,
            text = "Wonder",
        },
        {
            weight = 10,
            text = "the Good",
        },
        {
            weight = 10,
            text = "the Leaf",
        },
        {
            weight = 10,
            text = "Divine Compulsion",
        },
        {
            weight = 10,
            text = "Divine Intervention",
        },
        {
            weight = 10,
            text = "Intercession",
        },
        {
            weight = 10,
            text = "Miracles",
        },
        {
            weight = 10,
            text = "Salvation",
        },
        {
            weight = 10,
            text = "the Invisible Hand",
        },
        {
            weight = 10,
            text = "the Will of the Gods",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
