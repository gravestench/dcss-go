-- easy level book is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "easy level book",
    entries = {
        {
            weight = 1,
            text = "@_book_magic_@, and How To Use It",
        },
        {
            weight = 10,
            text = "@_the_book_magic_@ Continued",
        },
        {
            weight = 10,
            text = "@_the_book_magic_@ in Simple Steps",
        },
        {
            weight = 10,
            text = "@_the_book_magic_@, Part @level@",
        },
        {
            weight = 10,
            text = "A Primer on @_the_book_magic_@",
        },
        {
            weight = 10,
            text = "An Early Guide to @_the_book_magic_@",
        },
        {
            weight = 10,
            text = "Easy @_book_magic_@",
        },
        {
            weight = 2,
            text = "More @_book_magic_@",
        },
        {
            weight = 10,
            text = "Simple @_book_magic_@",
        },
        {
            weight = 1,
            text = "The Antepenultimate Guide to @_book_magic_@",
        },
        {
            weight = 10,
            text = "The Foundations of @_book_magic_@",
        },
        {
            weight = 2,
            text = "The Joy of @_book_magic_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
