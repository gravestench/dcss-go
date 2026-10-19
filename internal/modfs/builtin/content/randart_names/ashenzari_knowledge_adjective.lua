-- _ashenzari_knowledge_adjective_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_ashenzari_knowledge_adjective_",
    entries = {
        {
            weight = 10,
            text = "All-seeing",
        },
        {
            weight = 10,
            text = "Astrological",
        },
        {
            weight = 10,
            text = "Clairvoyant",
        },
        {
            weight = 10,
            text = "Cryptic",
        },
        {
            weight = 10,
            text = "Enlightened",
        },
        {
            weight = 10,
            text = "Enigmatic",
        },
        {
            weight = 10,
            text = "Esoteric",
        },
        {
            weight = 10,
            text = "Gnostic",
        },
        {
            weight = 10,
            text = "Manifest",
        },
        {
            weight = 10,
            text = "Mantic",
        },
        {
            weight = 10,
            text = "Omniscient",
        },
        {
            weight = 10,
            text = "Oracular",
        },
        {
            weight = 10,
            text = "Pangnostic",
        },
        {
            weight = 10,
            text = "Perceptive",
        },
        {
            weight = 10,
            text = "Prescient",
        },
        {
            weight = 10,
            text = "Profound",
        },
        {
            weight = 10,
            text = "Prophetic",
        },
        {
            weight = 10,
            text = "Revealing",
        },
        {
            weight = 10,
            text = "Sibylline",
        },
        {
            weight = 10,
            text = "Unveiling",
        },
        {
            weight = 10,
            text = "Visionary",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
