-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:663
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NEGATIVE_ENERGY_RESISTANCE",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "negative energy resistance",
    description =
        "You resist negative energy. Each level of this mutation reduces the amount of\ndamage" ..
        " taken from negative energy, along with the amount that it drains your\nhealth.",
    have = {
        "You resist negative energy. (rN+)",
        "You are quite resistant to negative energy. (rN++)",
        "You are immune to negative energy. (rN+++)",
    },
    gain = {
        "You feel resistant to negative energy.",
        "You feel more resistant to negative energy.",
        "You feel more resistant to negative energy.",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
