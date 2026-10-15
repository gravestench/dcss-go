-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:362
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ACUTE_VISION",
    status = "active",
    weight = 2,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "see invisible",
    description =
        "You have supernaturally acute eyesight, allowing you to see monsters that are\nhidden" ..
        " from mundane sight. This has no effect on your accuracy otherwise.",
    have = {
        "You have supernaturally acute eyesight. (SInv)",
        "",
        "",
    },
    gain = {
        "Your vision sharpens.",
        "",
        "",
    },
    lose = {
        "Your vision seems duller.",
        "",
        "",
    },
    tile_id = "TILEG_MUT_ACUTE_VISION",
}

register.definition(categories.MUTATIONS, definition)

return definition
