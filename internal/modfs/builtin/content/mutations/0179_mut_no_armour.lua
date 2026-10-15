-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2213
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_ARMOUR",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no armour",
    description = "You cannot wear armour.",
    have = {
        "You cannot wear armour.",
        "",
        "",
    },
    gain = {
        "You can no longer wear armour.",
        "",
        "",
    },
    lose = {
        "You can now wear armour.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
