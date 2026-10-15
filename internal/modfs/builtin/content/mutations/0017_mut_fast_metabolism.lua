-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:228

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FAST_METABOLISM",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "fast metabolism",
    have = {
        "You have a fast metabolism.",
        "You have a very fast metabolism.",
        "Your metabolism is lightning-fast.",
    },
    gain = {
        "You feel a little hungry.",
        "You feel a little hungry.",
        "You feel a little hungry.",
    },
    lose = {
        "Your metabolism slows.",
        "Your metabolism slows.",
        "Your metabolism slows.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
