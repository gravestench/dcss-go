-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:185
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SHOCK_RESISTANCE",
    status = "active",
    weight = 2,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "electricity resistance",
    description = "You resist electricity (rElec), taking less damage from it.",
    have = {
        "You are resistant to electric shocks. (rElec)",
        "",
        "",
    },
    gain = {
        "You feel insulated.",
        "",
        "",
    },
    lose = {
        "You feel conductive.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
