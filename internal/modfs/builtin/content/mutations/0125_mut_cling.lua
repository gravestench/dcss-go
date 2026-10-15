-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1707

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CLING",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "cling",
    have = {
        "You can cling to walls.",
        "",
        "",
    },
    gain = {
        "You feel sticky.",
        "",
        "",
    },
    lose = {
        "You feel slippery.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
