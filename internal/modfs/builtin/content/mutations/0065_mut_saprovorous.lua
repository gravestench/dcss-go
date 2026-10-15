-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:899

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SAPROVOROUS",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "saprovore",
    have = {
        "You can tolerate rotten meat.",
        "You can eat rotten meat.",
        "You thrive on rotten meat.",
    },
    gain = {
        "You hunger for rotting flesh.",
        "You hunger for rotting flesh.",
        "You hunger for rotting flesh.",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
