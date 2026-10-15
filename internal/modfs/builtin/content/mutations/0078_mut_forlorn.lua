-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1071
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FORLORN",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "forlorn",
    description = "You cannot, will not, and will never worship any god.",
    have = {
        "You shall have no god before yourself.",
        "",
        "",
    },
    gain = {
        "You feel forlorn.",
        "",
        "",
    },
    lose = {
        "You feel more spiritual.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
