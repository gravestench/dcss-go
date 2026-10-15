-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1682
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_JELLY_MISSILE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "jelly absorbing missiles",
    description =
        "When struck by a missile (such as an arrow or crossbow bolt), a jelly on your\nbody" ..
        " may eat it, healing you somewhat.",
    have = {
        "You have a small jelly attached to you that may absorb projectiles.",
        "",
        "",
    },
    gain = {
        "Your body partially splits into a small jelly.",
        "",
        "",
    },
    lose = {
        "The jelly growth is reabsorbed into your body.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
