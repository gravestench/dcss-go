-- _discomfort_weapon_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_discomfort_weapon_",
    entries = {
        {
            weight = 10,
            text = "Annoyance",
        },
        {
            weight = 10,
            text = "Anxiety",
        },
        {
            weight = 10,
            text = "Awkwardness",
        },
        {
            weight = 10,
            text = "Chagrin",
        },
        {
            weight = 10,
            text = "Desperation",
        },
        {
            weight = 10,
            text = "Discomfort",
        },
        {
            weight = 10,
            text = "Disgust",
        },
        {
            weight = 10,
            text = "Dismay",
        },
        {
            weight = 10,
            text = "Dissatisfaction",
        },
        {
            weight = 10,
            text = "Embarrassment",
        },
        {
            weight = 10,
            text = "Flawed Execution",
        },
        {
            weight = 10,
            text = "Foul Odours",
        },
        {
            weight = 10,
            text = "Frustration",
        },
        {
            weight = 10,
            text = "Gloom",
        },
        {
            weight = 10,
            text = "Inconvenience",
        },
        {
            weight = 10,
            text = "Irritation",
        },
        {
            weight = 10,
            text = "Malaise",
        },
        {
            weight = 10,
            text = "Shame",
        },
        {
            weight = 10,
            text = "Stickiness",
        },
        {
            weight = 10,
            text = "Uncomfortable Rashes",
        },
        {
            weight = 10,
            text = "Unpleasantness",
        },
        {
            weight = 10,
            text = "Urgency",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
