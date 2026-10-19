-- difficult level book is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "difficult level book",
    entries = {
        {
            weight = 50,
            text = "@_difficult level book owner_@",
        },
        {
            weight = 10,
            text = "The @_last_or_lost_@ @book_noun@ of @_the_powerful_caster_@",
        },
        {
            weight = 1,
            text = "@_the_book_magic_@ of @_the_powerful_caster_@",
        },
        {
            weight = 1,
            text = "The Testament of @_the_powerful_caster_@",
        },
        {
            weight = 1,
            text = "The Wisdom of @_the_powerful_caster_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
