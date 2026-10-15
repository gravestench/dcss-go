-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1143
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_PASSIVE_FREEZE",
    status = "active",
    weight = 1,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "passive freeze",
    description =
        "Foes who strike you in melee will be frozen, taking damage. This effect is\nguaranteed" ..
        " to trigger if your foe does any damage.",
    have = {
        "A frigid envelope surrounds you and freezes all who hurt you.",
        "",
        "",
    },
    gain = {
        "Your skin feels very cold.",
        "",
        "",
    },
    lose = {
        "Your skin warms up.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
