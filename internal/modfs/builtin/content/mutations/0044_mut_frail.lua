-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:607
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FRAIL",
    status = "active",
    weight = 10,
    max_level = 3,
    uses = {
        "bad",
        "xom",
    },
    form_based = false,
    short_description = "frail",
    description =
        "Your health is poor. Each level of this mutation worsens your health further\n(-10%" ..
        " HP).",
    have = {
        "You are frail. (-10% HP)",
        "You are very frail. (-20% HP)",
        "You are extremely frail. (-30% HP)",
    },
    gain = {
        "You feel frail.",
        "You feel frail.",
        "You feel frail.",
    },
    lose = {
        "You feel robust.",
        "You feel robust.",
        "You feel robust.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
