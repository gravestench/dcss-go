-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:400

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BREATHE_FLAMES",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "breathe flames",
    have = {
        "You can breathe flames.",
        "You can breathe fire.",
        "You can breathe blasts of fire.",
    },
    gain = {
        "Your throat feels hot.",
        "Your throat feels hot.",
        "Your throat feels hot.",
    },
    lose = {
        "A chill runs up and down your throat.",
        "A chill runs up and down your throat.",
        "A chill runs up and down your throat.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
