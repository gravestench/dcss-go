-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2297
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FLAT_HP",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "extra vitality",
    description =
        "You are built differently from most species, making you slightly harder to kill.\nEach" ..
        " level of this mutation increases your maximum health by 4 points.",
    have = {
        "You have superior vitality. (+4 MHP)",
        "You have much superior vitality. (+8 MHP)",
        "You have exceptionally superior vitality. (+12 MHP)",
    },
    gain = {
        "You feel less vital.",
        "You feel less vital.",
        "You feel less vital.",
    },
    lose = {
        "You feel more vital.",
        "You feel more vital.",
        "You feel more vital.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
