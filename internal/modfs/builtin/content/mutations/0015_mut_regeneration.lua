-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:201
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_REGENERATION",
    status = "active",
    weight = 2,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "regeneration",
    description =
        "You heal quickly. Each level of this mutation increases the rate at which you\nheal.",
    have = {
        "Your natural rate of healing is unusually fast.",
        "You heal very quickly.",
        "You regenerate.",
    },
    gain = {
        "You begin to heal more quickly.",
        "You begin to heal more quickly.",
        "You begin to regenerate.",
    },
    lose = {
        "Your rate of healing slows.",
        "Your rate of healing slows.",
        "Your rate of healing slows.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
