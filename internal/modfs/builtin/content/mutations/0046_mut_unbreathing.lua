-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:643

local categories = require("constants.catalog")

local definition = {
    id = "MUT_UNBREATHING",
    status = "removed",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "unbreathing",
    have = {
        "You can survive without breathing.",
        "You can survive without breathing, even under water.",
        "",
    },
    gain = {
        "You feel breathless.",
        "",
        "",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
