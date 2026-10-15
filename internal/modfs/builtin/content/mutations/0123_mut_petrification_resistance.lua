-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1690
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_PETRIFICATION_RESISTANCE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "petrification resistance",
    description = "You are immune to petrification.",
    have = {
        "You are immune to petrification.",
        "",
        "",
    },
    gain = {
        "Your body vibrates.",
        "",
        "",
    },
    lose = {
        "You briefly stop moving.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
