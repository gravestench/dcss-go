-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2288

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HP_CASTING",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "HP casting",
    have = {
        "Your magical power is your life essence.",
        "",
        "",
    },
    gain = {
        "Your magical power and health merge together.",
        "",
        "",
    },
    lose = {
        "Your life and magic unlink.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
