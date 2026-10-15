-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:591
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DEVOLUTION",
    status = "active",
    weight = 4,
    max_level = 2,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "devolution",
    description =
        "As you gain experience, your body's hidden potential will express itself in the\nform" ..
        " of new detrimental mutations.",
    have = {
        "You have hidden genetic defects.",
        "You have terrible hidden genetic defects.",
        "",
    },
    gain = {
        "You feel a hidden malignance growing inside you.",
        "The malignance inside you grows.",
        "",
    },
    lose = {
        "You no longer feel a malignance within.",
        "Your genetic malignance weakens.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
