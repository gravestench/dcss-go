-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2133
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MISSING_EYE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "missing an eye",
    description =
        "You are missing an eye, reducing the accuracy of your physical and magical\nattacks.",
    have = {
        "You are missing an eye, making it more difficult to aim.",
        "",
        "",
    },
    gain = {
        "Your right eye vanishes! The world loses its depth.",
        "",
        "",
    },
    lose = {
        "Your right eye suddenly reappears! The world regains its depth.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
