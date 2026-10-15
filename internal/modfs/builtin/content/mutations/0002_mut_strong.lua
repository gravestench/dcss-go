-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:46
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STRONG",
    status = "active",
    weight = 7,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "strong",
    description =
        "Your muscles have grown unnaturally strong. Each level of this mutation provides\n+4" ..
        " Strength, but the extra muscles slow your movements and thoughts, giving -1 to\nboth" ..
        " your Intelligence and Dexterity for each level.",
    have = {
        "Your muscles are strong. (Str +4, Int/Dex -1)",
        "Your muscles are very strong. (Str +8, Int/Dex -2)",
        "",
    },
    gain = {
        "",
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
