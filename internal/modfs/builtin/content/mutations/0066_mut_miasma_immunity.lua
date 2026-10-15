-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:913

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MIASMA_IMMUNITY",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "miasma immunity",
    have = {
        "You are immune to miasma.",
        "",
        "",
    },
    gain = {
        "You feel immune to miasma.",
        "",
        "",
    },
    lose = {
        "You feel vulnerable to miasma.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
