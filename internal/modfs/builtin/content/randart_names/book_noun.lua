-- book_noun is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "book_noun",
    entries = {
        {
            weight = 10,
            text = "Almanac",
        },
        {
            weight = 10,
            text = "Anthology",
        },
        {
            weight = 10,
            text = "Atlas",
        },
        {
            weight = 5,
            text = "Book",
        },
        {
            weight = 10,
            text = "Catalogue",
        },
        {
            weight = 10,
            text = "Codex",
        },
        {
            weight = 10,
            text = "Compendium",
        },
        {
            weight = 10,
            text = "Compilation",
        },
        {
            weight = 5,
            text = "Cyclopedia",
        },
        {
            weight = 10,
            text = "Directory",
        },
        {
            weight = 5,
            text = "Encyclopedia",
        },
        {
            weight = 10,
            text = "Folio",
        },
        {
            weight = 10,
            text = "Grimoire",
        },
        {
            weight = 10,
            text = "Handbook",
        },
        {
            weight = 5,
            text = "Incunable",
        },
        {
            weight = 5,
            text = "Incunabulum",
        },
        {
            weight = 10,
            text = "Octavo",
        },
        {
            weight = 10,
            text = "Omnibus",
        },
        {
            weight = 10,
            text = "Papyrus",
        },
        {
            weight = 10,
            text = "Parchment",
        },
        {
            weight = 10,
            text = "Precepts",
        },
        {
            weight = 10,
            text = "Quarto",
        },
        {
            weight = 10,
            text = "Secrets",
        },
        {
            weight = 10,
            text = "Spellbook",
        },
        {
            weight = 10,
            text = "Tome",
        },
        {
            weight = 10,
            text = "Vellum",
        },
        {
            weight = 10,
            text = "Volume",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
