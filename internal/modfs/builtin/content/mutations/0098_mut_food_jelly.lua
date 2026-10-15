-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1317

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FOOD_JELLY",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "spawn jellies when eating",
    have = {
        "You occasionally spawn a jelly by eating.",
        "",
        "",
    },
    gain = {
        "You feel more connected to the slimes.",
        "",
        "",
    },
    lose = {
        "Your connection to the slimes vanishes.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
