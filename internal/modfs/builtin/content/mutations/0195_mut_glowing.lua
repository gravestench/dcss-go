-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2347
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_GLOWING",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "glowing",
    description =
        "You glow in the dark. Foes hit you more often, your stealth is badly impaired,\nand" ..
        " your outline is easily seen even while you are otherwise invisible.",
    have = {
        "You glow in the dark.",
        "",
        "",
    },
    gain = {
        "Your body begins glowing.",
        "",
        "",
    },
    lose = {
        "You feel a bit dim.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
