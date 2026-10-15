-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:244

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SLOW_METABOLISM",
    status = "removed",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "slow metabolism",
    have = {
        "You have a slow metabolism.",
        "You need to consume almost no food.",
        "",
    },
    gain = {
        "Your metabolism slows.",
        "Your metabolism slows.",
        "",
    },
    lose = {
        "You feel a little hungry.",
        "You feel a little hungry.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
