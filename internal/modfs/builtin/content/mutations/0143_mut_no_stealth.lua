-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1887
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_STEALTH",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no stealth",
    description =
        "Your have no Stealth. You will always alert monsters when they see you, and\nthey will" ..
        " track you very effectively.",
    have = {
        "You cannot be stealthy.",
        "",
        "",
    },
    gain = {
        "You can no longer be stealthy.",
        "",
        "",
    },
    lose = {
        "You can once more be stealthy.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
