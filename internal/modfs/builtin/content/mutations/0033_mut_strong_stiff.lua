-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:440

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STRONG_STIFF",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "stiff muscles",
    have = {
        "Your muscles are strong, but stiff. (Str +1, Dex -1)",
        "Your muscles are very strong, but stiff. (Str +2, Dex -2)",
        "Your muscles are extremely strong, but stiff. (Str +3, Dex -3)",
    },
    gain = {
        "Your muscles feel sore.",
        "Your muscles feel sore.",
        "Your muscles feel sore.",
    },
    lose = {
        "Your muscles feel loose.",
        "Your muscles feel loose.",
        "Your muscles feel loose.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
