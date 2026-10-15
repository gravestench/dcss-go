-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1465
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_RUGGED_BROWN_SCALES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "rugged brown scales",
    description =
        "You are covered in brown scales, providing a small amount of protection. Each\nlevel" ..
        " of this mutation provides +1 AC and also increases your health slightly.",
    have = {
        "You are partially covered in rugged brown scales. (AC +1, +3% HP)",
        "You are mostly covered in rugged brown scales. (AC +2, +5% HP)",
        "You are completely covered in rugged brown scales. (AC +3, +7% HP)",
    },
    gain = {
        "Rugged brown scales grow over part of your body.",
        "Rugged brown scales spread over more of your body.",
        "Rugged brown scales cover your body completely.",
    },
    lose = {
        "Your rugged brown scales disappear.",
        "Your rugged brown scales recede somewhat.",
        "Your rugged brown scales recede somewhat.",
    },
    tile_id = "TILEG_MUT_RUGGED_BROWN_SCALES",
}

register.definition(categories.MUTATIONS, definition)

return definition
