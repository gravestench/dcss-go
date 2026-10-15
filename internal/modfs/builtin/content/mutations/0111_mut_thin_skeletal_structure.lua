-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1519
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_THIN_SKELETAL_STRUCTURE",
    status = "active",
    weight = 2,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "thin skeletal structure",
    description =
        "Your bones are light and porous. Each level of this mutation provides +2\nDexterity" ..
        " and Stealth+.",
    have = {
        "You have a somewhat thin skeletal structure. (Dex +2, Stealth+)",
        "You have a moderately thin skeletal structure. (Dex +4, Stealth++)",
        "You have an unnaturally thin skeletal structure. (Dex +6, Stealth+++)",
    },
    gain = {
        "Your bones become slightly less dense.",
        "Your bones become somewhat less dense.",
        "Your bones become less dense.",
    },
    lose = {
        "Your skeletal structure returns to normal.",
        "Your skeletal structure densifies.",
        "Your skeletal structure densifies.",
    },
    tile_id = "TILEG_MUT_THIN_SKELETAL_STRUCTURE",
}

register.definition(categories.MUTATIONS, definition)

return definition
