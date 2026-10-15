-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1009

local categories = require("constants.catalog")

local definition = {
    id = "MUT_LOW_MAGIC",
    status = "active",
    weight = 9,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "low MP",
    have = {
        "Your magical capacity is low. (-10% MP)",
        "Your magical capacity is very low. (-20% MP)",
        "Your magical capacity is extremely low. (-30% MP)",
    },
    gain = {
        "You feel less energetic.",
        "You feel less energetic.",
        "You feel less energetic.",
    },
    lose = {
        "You feel more energetic.",
        "You feel more energetic.",
        "You feel more energetic.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
