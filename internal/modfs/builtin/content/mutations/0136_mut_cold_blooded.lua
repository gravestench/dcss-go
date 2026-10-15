-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1817
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_COLD_BLOODED",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = true,
    short_description = "cold-blooded",
    description =
        "You are endothermic. When struck by a cold attack, you may be slowed until your\nblood" ..
        " warms again.",
    have = {
        "You are cold-blooded and may be slowed by cold attacks.",
        "",
        "",
    },
    gain = {
        "You feel cold-blooded.",
        "",
        "",
    },
    lose = {
        "You feel warm-blooded.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
