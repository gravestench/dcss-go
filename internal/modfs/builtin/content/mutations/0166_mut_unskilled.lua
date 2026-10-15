-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2097
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_UNSKILLED",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "unskilled",
    description =
        "It takes you more experience to improve your skills. Each level of this\nsacrifice" ..
        " makes your skills cost even more.",
    have = {
        "You are somewhat unskilled. (-1 Apt)",
        "You are unskilled. (-2 Apt)",
        "You are extremely unskilled. (-3 Apt)",
    },
    gain = {
        "You feel less skilled.",
        "You feel less skilled.",
        "You feel less skilled.",
    },
    lose = {
        "You regain all your skill.",
        "You regain some skill.",
        "You regain some skill.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
