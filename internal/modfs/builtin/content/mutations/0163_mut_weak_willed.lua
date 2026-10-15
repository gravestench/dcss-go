-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2061
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_WEAK_WILLED",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "weak-willed",
    description =
        "You have an unnaturally weak will, reducing your resistance to certain types\nof" ..
        " hostile magic. Each level of this mutation reduces your willpower further.",
    have = {
        "You are slightly weak-willed. (Will-)",
        "You are weak-willed. (Will--)",
        "You are extremely weak-willed. (Will---)",
    },
    gain = {
        "You feel weak-willed.",
        "You feel more weak-willed.",
        "You feel more weak-willed.",
    },
    lose = {
        "You no longer feel weak-willed.",
        "You feel less weak-willed.",
        "You feel less weak-willed.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
