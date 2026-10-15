-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:289

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TELEPORT_CONTROL",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "teleport control",
    have = {
        "You can control translocations.",
        "",
        "",
    },
    gain = {
        "You feel controlled.",
        "",
        "",
    },
    lose = {
        "You feel random.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
