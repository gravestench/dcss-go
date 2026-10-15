-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2205
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_GRASPING",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no weapons or thrown items",
    description = "You are incapable of wielding weapons or throwing items.",
    have = {
        "You are incapable of wielding weapons or throwing items.",
        "",
        "",
    },
    gain = {
        "You can no longer grasp objects.",
        "",
        "",
    },
    lose = {
        "You can now grasp objects.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
