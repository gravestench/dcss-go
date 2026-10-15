-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:575
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_EVOLUTION",
    status = "active",
    weight = 4,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "evolution",
    description =
        "As you gain experience, your body's hidden potential will express itself in the\nform" ..
        " of new beneficial mutations.",
    have = {
        "You have hidden genetic potential.",
        "You have great hidden genetic potential.",
        "",
    },
    gain = {
        "You feel a hidden potential growing inside you.",
        "Your hidden genetic potential grows.",
        "",
    },
    lose = {
        "You no longer feel a hidden potential within.",
        "Your hidden genetic potential wanes.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
