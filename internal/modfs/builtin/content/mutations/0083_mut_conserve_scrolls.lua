-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1126

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CONSERVE_SCROLLS",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "conserve scrolls",
    have = {
        "You are very good at protecting items from fire.",
        "",
        "",
    },
    gain = {
        "You feel less concerned about heat.",
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
