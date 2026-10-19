-- _the_book_magic_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_the_book_magic_",
    entries = {
        {
            weight = 10,
            text = "the Arcane Arts",
        },
        {
            weight = 5,
            text = "the Occult",
        },
        {
            weight = 1,
            text = "the Hermit's Heritage",
        },
        {
            weight = 180,
            text = "@_book_magic_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
