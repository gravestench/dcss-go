-- _evil_stuff_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_evil_stuff_",
    entries = {
        {
            weight = 10,
            text = "Abomination",
        },
        {
            weight = 10,
            text = "Abuse",
        },
        {
            weight = 10,
            text = "Ancient Evil",
        },
        {
            weight = 10,
            text = "Corruption",
        },
        {
            weight = 10,
            text = "Defilement",
        },
        {
            weight = 10,
            text = "Deformation",
        },
        {
            weight = 10,
            text = "Demonkind",
        },
        {
            weight = 10,
            text = "Evil",
        },
        {
            weight = 10,
            text = "Hell's Wrath",
        },
        {
            weight = 10,
            text = "Infection",
        },
        {
            weight = 10,
            text = "Mutilation",
        },
        {
            weight = 10,
            text = "Nightmares",
        },
        {
            weight = 10,
            text = "Perversion",
        },
        {
            weight = 10,
            text = "Putrescence",
        },
        {
            weight = 10,
            text = "Shrieking Terror",
        },
        {
            weight = 10,
            text = "the Beast",
        },
        {
            weight = 10,
            text = "the Crawling Thing",
        },
        {
            weight = 10,
            text = "the Dead",
        },
        {
            weight = 10,
            text = "the Evil Eye",
        },
        {
            weight = 10,
            text = "the Ghost",
        },
        {
            weight = 10,
            text = "the Living Dead",
        },
        {
            weight = 10,
            text = "the Lurker",
        },
        {
            weight = 10,
            text = "the Reaper",
        },
        {
            weight = 10,
            text = "the Spectre",
        },
        {
            weight = 10,
            text = "the Thing",
        },
        {
            weight = 10,
            text = "the Undead",
        },
        {
            weight = 10,
            text = "the Unliving",
        },
        {
            weight = 10,
            text = "the Unspeakable One",
        },
        {
            weight = 10,
            text = "the Wraith",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
