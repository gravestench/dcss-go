-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:217
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_INHIBITED_REGENERATION",
    status = "active",
    weight = 3,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "inhibited regeneration",
    description =
        "You do not heal over time while foes are in sight. Other sources of healing,\nsuch as" ..
        " potions, are unaffected.",
    have = {
        "You do not regenerate when monsters are visible.",
        "",
        "",
    },
    gain = {
        "Your regeneration stops near monsters.",
        "",
        "",
    },
    lose = {
        "You begin to regenerate regardless of the presence of monsters.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
