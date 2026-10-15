-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:993

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HIGH_MAGIC",
    status = "active",
    weight = 2,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "high MP",
    have = {
        "You have an increased reservoir of magic. (+10% MP)",
        "You have a considerably increased reservoir of magic. (+20% MP)",
        "You have a greatly increased reservoir of magic. (+30% MP)",
    },
    gain = {
        "You feel more energetic.",
        "You feel more energetic.",
        "You feel more energetic.",
    },
    lose = {
        "You feel less energetic.",
        "You feel less energetic.",
        "You feel less energetic.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
