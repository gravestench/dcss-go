-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2320
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DAYSTALKER",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "+LOS",
    description =
        "The darkness flees at your approach, allowing an extended range of vision and\nranged" ..
        " attack (+1 line of sight), but also allowing you to be seen and\npotentially targeted" ..
        " from further away.",
    have = {
        "You have an extended range of vision and can be seen from far away.",
        "",
        "",
    },
    gain = {
        "The darkness flees at your approach.",
        "",
        "",
    },
    lose = {
        "The shadows grow bolder once more.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
