-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1740
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BLACK_MARK",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "black mark",
    description =
        "When you strike a foe in melee, the black mark on your body may debilitate\nthem. This" ..
        " can weaken foes, drain their health, or disrupt their magic.",
    have = {
        "Your melee attacks may debilitate your foes.",
        "",
        "",
    },
    gain = {
        "An ominous black mark forms on your body.",
        "",
        "",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
