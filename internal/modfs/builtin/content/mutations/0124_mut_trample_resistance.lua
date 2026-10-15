-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1699

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TRAMPLE_RESISTANCE",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "trample resistance",
    have = {
        "You are resistant to trampling.",
        "",
        "",
    },
    gain = {
        "You feel steady.",
        "",
        "",
    },
    lose = {
        "You feel unsteady.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
