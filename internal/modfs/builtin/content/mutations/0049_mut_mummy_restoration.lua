-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:678

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MUMMY_RESTORATION",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "restore body",
    have = {
        "You can restore your body by infusing magical energy.",
        "",
        "",
    },
    gain = {
        "You can now infuse your body with magic to restore decomposition.",
        "",
        "",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
