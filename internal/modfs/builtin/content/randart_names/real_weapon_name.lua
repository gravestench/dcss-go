-- _real_weapon_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_real_weapon_name_",
    entries = {
        {
            weight = 10,
            text = "Arbiter",
        },
        {
            weight = 10,
            text = "Arcanum",
        },
        {
            weight = 10,
            text = "Concordance",
        },
        {
            weight = 10,
            text = "Conservator",
        },
        {
            weight = 10,
            text = "Death Rattle",
        },
        {
            weight = 10,
            text = "Dragon's Tongue",
        },
        {
            weight = 10,
            text = "Earthworm",
        },
        {
            weight = 10,
            text = "Embalmer",
        },
        {
            weight = 10,
            text = "Eviscerator",
        },
        {
            weight = 10,
            text = "Grim",
        },
        {
            weight = 10,
            text = "Grim Tooth",
        },
        {
            weight = 10,
            text = "Hell-Harrower",
        },
        {
            weight = 10,
            text = "Hellblazer",
        },
        {
            weight = 10,
            text = "Leviticus",
        },
        {
            weight = 10,
            text = "Lifebane",
        },
        {
            weight = 10,
            text = "Murmur",
        },
        {
            weight = 10,
            text = "Pendulum",
        },
        {
            weight = 10,
            text = "Sarcophage",
        },
        {
            weight = 10,
            text = "Tormentor",
        },
        {
            weight = 10,
            text = "Transmigrator",
        },
        {
            weight = 10,
            text = "Trog's @_anger_quality_@",
        },
        {
            weight = 10,
            text = "Ultimatum",
        },
        {
            weight = 10,
            text = "Undertaker",
        },
        {
            weight = 5,
            text = "Widowermaker",
        },
        {
            weight = 5,
            text = "Widowmaker",
        },
        {
            weight = 10,
            text = "Worm",
        },
        {
            weight = 10,
            text = "Worm's Wrath",
        },
        {
            weight = 10,
            text = "Gram",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
