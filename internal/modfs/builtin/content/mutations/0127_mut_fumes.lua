-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1731

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FUMES",
    status = "removed",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "fuming",
    have = {
        "You emit clouds of smoke.",
        "You frequently emit clouds of smoke.",
        "",
    },
    gain = {
        "You fume.",
        "You fume more.",
        "",
    },
    lose = {
        "You stop fuming.",
        "You fume less.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
