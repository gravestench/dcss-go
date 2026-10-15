-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1483
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SLIMY_GREEN_SCALES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "slimy green scales",
    description =
        "You are covered in green scales, providing a small amount of protection. Each\nlevel" ..
        " of this mutation provides more AC. The third level of this mutation also\nprovides" ..
        " resistance to poison.",
    have = {
        "You are partially covered in slimy green scales. (AC +2)",
        "You are mostly covered in slimy green scales. (AC +3)",
        "You are completely covered in slimy green scales. (AC +4, rPois)",
    },
    gain = {
        "Slimy green scales grow over part of your body.",
        "Slimy green scales spread over more of your body.",
        "Slimy green scales cover your body completely.",
    },
    lose = {
        "Your slimy green scales disappear.",
        "Your slimy green scales recede somewhat.",
        "Your slimy green scales recede somewhat.",
    },
    tile_id = "TILEG_MUT_SLIMY_GREEN_SCALES",
}

register.definition(categories.MUTATIONS, definition)

return definition
