-- _book_noun_on_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_book_noun_on_",
    entries = {
        {
            weight = 10,
            text = "Collected Works",
        },
        {
            weight = 10,
            text = "Commentary",
        },
        {
            weight = 10,
            text = "Discourse",
        },
        {
            weight = 5,
            text = "Discursus",
        },
        {
            weight = 10,
            text = "Disquisition",
        },
        {
            weight = 10,
            text = "Dissertation",
        },
        {
            weight = 5,
            text = "Enchiridion",
        },
        {
            weight = 10,
            text = "Essays",
        },
        {
            weight = 5,
            text = "Excursus",
        },
        {
            weight = 10,
            text = "Exposition",
        },
        {
            weight = 10,
            text = "Guide",
        },
        {
            weight = 10,
            text = "Guidebook",
        },
        {
            weight = 10,
            text = "Lectures",
        },
        {
            weight = 10,
            text = "Lessons",
        },
        {
            weight = 10,
            text = "Meditations",
        },
        {
            weight = 10,
            text = "Monograph",
        },
        {
            weight = 5,
            text = "Opusculum",
        },
        {
            weight = 10,
            text = "Reference Book",
        },
        {
            weight = 10,
            text = "Teachings",
        },
        {
            weight = 10,
            text = "Textbook",
        },
        {
            weight = 10,
            text = "Tractate",
        },
        {
            weight = 10,
            text = "Treatise",
        },
        {
            weight = 5,
            text = "Vademecum",
        },
        {
            weight = 10,
            text = "Verses",
        },
        {
            weight = 10,
            text = "Writings",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
