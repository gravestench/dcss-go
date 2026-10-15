-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:432

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BLINK",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "blink",
    have = {
        "You can translocate small distances at will.",
        "",
        "",
    },
    gain = {
        "You feel jittery.",
        "",
        "",
    },
    lose = {
        "You no longer feel jittery.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
