-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:852

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BREATHE_POISON",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "breathe poison",
    have = {
        "You can exhale a cloud of poison.",
        "",
        "",
    },
    gain = {
        "You taste something nasty.",
        "",
        "",
    },
    lose = {
        "Your breath is less nasty.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
