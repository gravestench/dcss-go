-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1927
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_ARMOUR_SKILL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "inability to train armour",
    description = "Your Armour skill is 0 and you cannot train the skill.",
    have = {
        "You cannot train Armour skill.",
        "",
        "",
    },
    gain = {
        "You can no longer train Armour skill.",
        "",
        "",
    },
    lose = {
        "You can once more train Armour skill.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
