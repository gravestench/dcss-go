-- death_or_doom is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "death_or_doom",
    entries = {
        {
            weight = 10,
            text = "Bloody Death",
        },
        {
            weight = 10,
            text = "Certain Death",
        },
        {
            weight = 10,
            text = "Death",
        },
        {
            weight = 10,
            text = "Exquisite Death",
        },
        {
            weight = 10,
            text = "Imminent Death",
        },
        {
            weight = 10,
            text = "Instant Death",
        },
        {
            weight = 10,
            text = "Pain and Death",
        },
        {
            weight = 10,
            text = "Painful Death",
        },
        {
            weight = 10,
            text = "Quick Death",
        },
        {
            weight = 10,
            text = "Slow Death",
        },
        {
            weight = 10,
            text = "Sudden Death",
        },
        {
            weight = 10,
            text = "Uncertain Death",
        },
        {
            weight = 10,
            text = "Untimely Demise",
        },
        {
            weight = 10,
            text = "Destruction",
        },
        {
            weight = 10,
            text = "Disembowelment",
        },
        {
            weight = 10,
            text = "Doom",
        },
        {
            weight = 10,
            text = "Evisceration",
        },
        {
            weight = 10,
            text = "Execution",
        },
        {
            weight = 10,
            text = "Extermination",
        },
        {
            weight = 10,
            text = "Extinguishment",
        },
        {
            weight = 10,
            text = "Peril",
        },
        {
            weight = 10,
            text = "Premature Burial",
        },
        {
            weight = 10,
            text = "Anguish",
        },
        {
            weight = 10,
            text = "Dismemberment",
        },
        {
            weight = 10,
            text = "Excruciating Pain",
        },
        {
            weight = 10,
            text = "Exquisite Torment",
        },
        {
            weight = 10,
            text = "Infinite Pain",
        },
        {
            weight = 10,
            text = "Misery",
        },
        {
            weight = 10,
            text = "Terror",
        },
        {
            weight = 10,
            text = "Woe",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
