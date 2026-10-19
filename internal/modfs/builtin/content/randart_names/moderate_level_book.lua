-- moderate level book is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "moderate level book",
    entries = {
        {
            weight = 10,
            text = "@_the_book_magic_@, Part @level@",
        },
        {
            weight = 10,
            text = "Advanced @_book_magic_@",
        },
        {
            weight = 10,
            text = "Advanced Steps in @_the_book_magic_@",
        },
        {
            weight = 2,
            text = "Even More @_book_magic_@",
        },
        {
            weight = 10,
            text = "Further Progress in @_book_magic_@",
        },
        {
            weight = 10,
            text = "Further Steps in @_the_book_magic_@",
        },
        {
            weight = 1,
            text = "Improving Your @_book_magic_@",
        },
        {
            weight = 10,
            text = "Sophisticated @_book_magic_@",
        },
        {
            weight = 10,
            text = "The Advanced Guide to @_the_book_magic_@",
        },
        {
            weight = 1,
            text = "The Penultimate Guide to @_book_magic_@",
        },
        {
            weight = 10,
            text = "The Second Course in @_book_magic_@",
        },
        {
            weight = 1,
            text = "Yet Another @book_noun@ About @_book_magic_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
