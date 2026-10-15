-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1448

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ROUGH_BLACK_SCALES",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "rough black scales",
    have = {
        "You are partially covered in rough black scales. (AC +2, Dex -1)",
        "You are mostly covered in rough black scales. (AC +5, Dex -2)",
        "You are completely covered in rough black scales. (AC +8, Dex -3)",
    },
    gain = {
        "Rough black scales grow over part of your body.",
        "Rough black scales spread over more of your body.",
        "Rough black scales cover your body completely.",
    },
    lose = {
        "Your rough black scales disappear.",
        "Your rough black scales recede somewhat.",
        "Your rough black scales recede somewhat.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
