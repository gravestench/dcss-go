-- starting level book is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "starting level book",
    entries = {
        {
            weight = 2,
            text = "@_the_book_magic_@ 101",
        },
        {
            weight = 10,
            text = "@_the_book_magic_@ for @_beginners_@",
        },
        {
            weight = 10,
            text = "@_the_book_magic_@, Part One",
        },
        {
            weight = 10,
            text = "A Beginning Course on @_the_book_magic_@",
        },
        {
            weight = 10,
            text = "A Tutorial on @_the_book_magic_@",
        },
        {
            weight = 2,
            text = "An Initiation to @_the_book_magic_@",
        },
        {
            weight = 10,
            text = "An Introduction to @_the_book_magic_@",
        },
        {
            weight = 10,
            text = "First Steps in @_the_book_magic_@",
        },
        {
            weight = 1,
            text = "So You Want to Learn @_the_book_magic_@",
        },
        {
            weight = 10,
            text = "Starting @_the_book_magic_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
