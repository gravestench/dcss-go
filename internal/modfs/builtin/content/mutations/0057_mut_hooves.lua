-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:784
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HOOVES",
    status = "active",
    weight = 5,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "hooves",
    description =
        "You have hooves, allowing you to kick foes when launching melee attacks if you\naren't" ..
        " wearing boots. Each level of this mutation makes your hooves harder and\nstronger." ..
        " The third level of this mutation prevents you from wearing boots.",
    have = {
        "You have large cloven feet.",
        "You have hoof-like feet.",
        "You have hooves in place of feet.",
    },
    gain = {
        "Your feet thicken and deform.",
        "Your feet thicken and deform.",
        "Your feet have mutated into hooves.",
    },
    lose = {
        "Your hooves expand and flesh out into feet!",
        "Your hooves look more like feet.",
        "Your hooves look more like feet.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
