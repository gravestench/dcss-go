-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:890
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BIG_WINGS",
    status = "active",
    weight = 4,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "big wings",
    description = "You have big, strong wings, capable of bearing you through the air.",
    have = {
        "Your large and strong wings let you fly.",
        "",
        "",
    },
    gain = {
        "Your wings grow larger and stronger.",
        "",
        "",
    },
    lose = {
        "Your wings shrivel and weaken.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
