-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2111
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_INEXPERIENCED",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "inexperienced",
    description = "You are inexperienced, and unable to fully gain 27 levels.",
    have = {
        "You are somewhat inexperienced. (-1 XL)",
        "You are inexperienced. (-2 XL)",
        "You are extremely inexperienced. (-3 XL)",
    },
    gain = {
        "You feel less experienced.",
        "You feel less experienced.",
        "You feel less experienced.",
    },
    lose = {
        "You regain all your potential.",
        "You regain some potential.",
        "You regain some potential.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
