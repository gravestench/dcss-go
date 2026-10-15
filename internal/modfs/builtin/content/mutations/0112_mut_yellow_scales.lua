-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1537
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_YELLOW_SCALES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "yellow scales",
    description =
        "You are covered in yellow scales, providing a small amount of protection. Each\nlevel" ..
        " of this mutation provides more AC. The third level of this mutation also\nprovides" ..
        " resistance to acid and corrosion.",
    have = {
        "You are partially covered in yellow scales. (AC +2)",
        "You are mostly covered in yellow scales. (AC +3)",
        "You are completely covered in yellow scales. (AC +4, rCorr)",
    },
    gain = {
        "Yellow scales grow over part of your body.",
        "Yellow scales spread over more of your body.",
        "Yellow scales cover your body completely.",
    },
    lose = {
        "Your yellow scales disappear.",
        "Your yellow scales recede somewhat.",
        "Your yellow scales recede somewhat.",
    },
    tile_id = "TILEG_MUT_YELLOW_SCALES",
}

register.definition(categories.MUTATIONS, definition)

return definition
