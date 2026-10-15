-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:118
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_COLD_RESISTANCE",
    status = "active",
    weight = 4,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "cold resistance",
    description =
        "You resist cold. Each level of this mutation reduces the amount of damage taken\nfrom" ..
        " cold.",
    have = {
        "Your flesh is cold resistant. (rC+)",
        "Your flesh is very cold resistant. (rC++)",
        "Your flesh is almost immune to the effects of cold. (rC+++)",
    },
    gain = {
        "You feel resistant to cold.",
        "You feel more resistant to cold.",
        "You feel more resistant to cold.",
    },
    lose = {
        "You no longer feel cold resistant.",
        "You feel less cold resistant.",
        "You feel less cold resistant.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
