-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2264
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MERTAIL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "mertail",
    description =
        "Your morphogenic matrix is unstable, allowing your lower body to shift to\na powerful" ..
        " aquatic tail when in shallow or deep water. It will quickly\nreform into legs once" ..
        " you leave the water. When in merform, your tail allows\nyou to tail-slap foes when" ..
        " launching melee attacks.",
    have = {
        "Your lower body shifts to a powerful aquatic tail in water.",
        "",
        "",
    },
    gain = {
        "Your legs feel aquatic.",
        "",
        "",
    },
    lose = {
        "Your legs no longer feel aquatic.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
