-- _difficult level book owner_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_difficult level book owner_",
    entries = {
        {
            weight = 10,
            text = "A Thorough Guide to @_the_book_magic_@",
        },
        {
            weight = 1,
            text = "Mastering @_book_magic_@",
        },
        {
            weight = 10,
            text = "The @_last_or_lost_@ Secrets of @_the_book_magic_@",
        },
        {
            weight = 10,
            text = "The @book_noun@ of Greatest Risks and Utility",
        },
        {
            weight = 10,
            text = "The Arcane Secrets of @_book_magic_@",
        },
        {
            weight = 10,
            text = "The Intricacies of @_the_book_magic_@",
        },
        {
            weight = 1,
            text = "The Ultimate Guide to @_book_magic_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
