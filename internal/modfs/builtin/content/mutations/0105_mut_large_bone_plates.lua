-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1411
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_LARGE_BONE_PLATES",
    status = "active",
    weight = 2,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "large bone plates",
    description =
        "You are covered in bone plates, providing a small amount of shielding. Each\nlevel of" ..
        " this mutation provides more SH.",
    have = {
        "You are partially covered in large bone plates. (SH +4)",
        "You are mostly covered in large bone plates. (SH +6)",
        "You are completely covered in large bone plates. (SH +8)",
    },
    gain = {
        "Large bone plates grow over parts of your arms.",
        "Large bone plates spread over more of your arms.",
        "Large bone plates cover your arms completely.",
    },
    lose = {
        "Your large bone plates disappear.",
        "Your large bone plates recede somewhat.",
        "Your large bone plates recede somewhat.",
    },
    tile_id = "TILEG_MUT_LARGE_BONE_PLATES",
}

register.definition(categories.MUTATIONS, definition)

return definition
