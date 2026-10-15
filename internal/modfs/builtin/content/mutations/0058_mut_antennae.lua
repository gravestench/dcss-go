-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:800
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ANTENNAE",
    status = "active",
    weight = 4,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "antennae",
    description =
        "You have antennae, allowing you to sense nearby monsters, but preventing you\nfrom" ..
        " wearing helmets. Each level of this mutation lets you sense monsters from\nfurther" ..
        " away. The third level of this mutation prevents you from wearing any\ntype of" ..
        " headgear, and allows you to see invisible monsters.",
    have = {
        "You have a pair of small antennae on your head.",
        "You have a pair of antennae on your head.",
        "You have a pair of large antennae on your head. (SInv)",
    },
    gain = {
        "A pair of antennae grows on your head!",
        "The antennae on your head grow some more.",
        "The antennae on your head grow some more.",
    },
    lose = {
        "The antennae on your head shrink away.",
        "The antennae on your head shrink a bit.",
        "The antennae on your head shrink a bit.",
    },
    tile_id = "TILEG_MUT_ANTENNAE",
}

register.definition(categories.MUTATIONS, definition)

return definition
