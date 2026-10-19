-- _book_magic_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_book_magic_",
    entries = {
        {
            weight = 5,
            text = "Casting",
        },
        {
            weight = 5,
            text = "Hermeneutics",
        },
        {
            weight = 10,
            text = "Incantation",
        },
        {
            weight = 10,
            text = "Magic",
        },
        {
            weight = 5,
            text = "Rites and Rhymes",
        },
        {
            weight = 5,
            text = "Secret Knowledge",
        },
        {
            weight = 10,
            text = "Sorcery",
        },
        {
            weight = 5,
            text = "Spellcasting",
        },
        {
            weight = 10,
            text = "Spellcraft",
        },
        {
            weight = 10,
            text = "Spellweaving",
        },
        {
            weight = 10,
            text = "Thaumaturgy",
        },
        {
            weight = 10,
            text = "Theurgy",
        },
        {
            weight = 10,
            text = "Willworking",
        },
        {
            weight = 10,
            text = "Witchcraft",
        },
        {
            weight = 10,
            text = "Witchery",
        },
        {
            weight = 5,
            text = "Wizarding",
        },
        {
            weight = 10,
            text = "Wizardry",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
