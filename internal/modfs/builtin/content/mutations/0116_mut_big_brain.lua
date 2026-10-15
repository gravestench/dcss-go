-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1605
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BIG_BRAIN",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "big brain",
    description =
        "What's up? You have a big brain. Each level of this mutation provides +2" ..
        "\nIntelligence. The third level of this mutation also makes you less likely to" ..
        "\nmiscast spells.",
    have = {
        "You have an unusually large brain. (Int +2)",
        "You have an extremely huge brain. (Int +4)",
        "You have an absolutely massive brain. (Int +6, Wiz)",
    },
    gain = {
        "Your brain expands.",
        "Your brain expands.",
        "Your brain expands to incredible size.",
    },
    lose = {
        "Your brain returns to normal size.",
        "Your brain shrinks.",
        "Your brain shrinks.",
    },
    tile_id = "TILEG_MUT_BIG_BRAIN",
}

register.definition(categories.MUTATIONS, definition)

return definition
