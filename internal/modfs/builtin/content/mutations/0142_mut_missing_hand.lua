-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1879
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MISSING_HAND",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "missing a hand",
    description =
        "You are considerably less handy than you used to be. You cannot wield\ntwo-handed" ..
        " weapons, wear a shield, launch off-handed attacks, or use more than\none magical ring" ..
        " at a time.",
    have = {
        "You are missing a hand.",
        "",
        "",
    },
    gain = {
        "One of your hands has vanished, leaving only a stump!",
        "",
        "",
    },
    lose = {
        "Your stump has regrown into a hand!",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
