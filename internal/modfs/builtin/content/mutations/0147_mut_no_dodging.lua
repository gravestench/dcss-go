-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1919
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_DODGING",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "inability to train dodging",
    description = "Your Dodging skill is 0 and you cannot train the skill.",
    have = {
        "You cannot train Dodging skill.",
        "",
        "",
    },
    gain = {
        "You can no longer train Dodging skill.",
        "",
        "",
    },
    lose = {
        "You can once more train Dodging skill.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
