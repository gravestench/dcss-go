-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1375
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ICY_BLUE_SCALES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "icy blue scales",
    description =
        "You are covered in blue scales, providing a small amount of protection. Each\nlevel of" ..
        " this mutation provides more AC. The third level of this mutation also\nprovides" ..
        " resistance to cold.",
    have = {
        "You are partially covered in icy blue scales. (AC +2)",
        "You are mostly covered in icy blue scales. (AC +3)",
        "You are completely covered in icy blue scales. (AC +4, rC+)",
    },
    gain = {
        "Icy blue scales grow over part of your body.",
        "Icy blue scales spread over more of your body.",
        "Icy blue scales cover your body completely.",
    },
    lose = {
        "Your icy blue scales disappear.",
        "Your icy blue scales recede somewhat.",
        "Your icy blue scales recede somewhat.",
    },
    tile_id = "TILEG_MUT_ICY_BLUE_SCALES",
}

register.definition(categories.MUTATIONS, definition)

return definition
