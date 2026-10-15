-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:624
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ROBUST",
    status = "active",
    weight = 5,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "robust",
    description =
        "You can take a beating. Each level of this mutation improves your health\nfurther" ..
        " (+10% HP).",
    have = {
        "You are robust. (+10% HP)",
        "You are very robust. (+20% HP)",
        "You are extremely robust. (+30% HP)",
    },
    gain = {
        "You feel robust.",
        "You feel robust.",
        "You feel robust.",
    },
    lose = {
        "You feel frail.",
        "You feel frail.",
        "You feel frail.",
    },
    tile_id = "TILEG_MUT_ROBUST",
}

register.definition(categories.MUTATIONS, definition)

return definition
