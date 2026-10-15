-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:960
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ARMOURED_TAIL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "armoured tail",
    description =
        "You have a large armoured tail, allowing you to tail-slap foes when launching\nmelee" ..
        " attacks.",
    have = {
        "You have a long armoured tail.",
        "",
        "",
    },
    gain = {
        "",
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
