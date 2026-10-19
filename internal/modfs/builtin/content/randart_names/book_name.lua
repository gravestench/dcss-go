-- book_name is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "book_name",
    entries = {
        {
            weight = 9,
            text = "@book_noun@ of",
        },
        {
            weight = 4,
            text = "@_book_noun_on_@ on",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
