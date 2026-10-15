-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1429
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MOLTEN_SCALES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "molten scales",
    description =
        "You are covered in molten scales, providing a small amount of protection. Each\nlevel" ..
        " of this mutation provides more AC. The third level of this mutation also\nprovides" ..
        " resistance to fire.",
    have = {
        "You are partially covered in molten scales. (AC +2)",
        "You are mostly covered in molten scales. (AC +3)",
        "You are completely covered in molten scales. (AC +4, rF+)",
    },
    gain = {
        "Molten scales grow over part of your body.",
        "Molten scales spread over more of your body.",
        "Molten scales cover your body completely.",
    },
    lose = {
        "Your molten scales disappear.",
        "Your molten scales recede somewhat.",
        "Your molten scales recede somewhat.",
    },
    tile_id = "TILEG_MUT_MOLTEN_SCALES",
}

register.definition(categories.MUTATIONS, definition)

return definition
