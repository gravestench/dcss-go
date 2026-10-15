-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:82

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CARNIVOROUS",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "carnivore",
    have = {
        "You are carnivorous and can eat meat at any time.",
        "",
        "",
    },
    gain = {
        "You hunger for flesh.",
        "",
        "",
    },
    lose = {
        "You feel able to eat a more balanced diet.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
