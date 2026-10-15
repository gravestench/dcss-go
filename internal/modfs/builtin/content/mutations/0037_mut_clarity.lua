-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:499
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CLARITY",
    status = "active",
    weight = 6,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "clarity",
    description =
        "Your mind is exceptionally clear, preventing you from becoming confused,\nmesmerised," ..
        " or supernaturally afraid. You also cannot become involuntarily\nenraged.",
    have = {
        "You possess an exceptional clarity of mind.",
        "",
        "",
    },
    gain = {
        "Your thoughts seem clearer.",
        "",
        "",
    },
    lose = {
        "Your thinking seems confused.",
        "",
        "",
    },
    tile_id = "TILEG_MUT_CLARITY",
}

register.definition(categories.MUTATIONS, definition)

return definition
