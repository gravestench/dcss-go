-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2197
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STEAM_RESISTANCE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "steam resistance",
    description = "You are immune to the damage from steam breath and steam clouds.",
    have = {
        "You are immune to the effects of steam.",
        "",
        "",
    },
    gain = {
        "You are now immune to the effects of steam.",
        "",
        "",
    },
    lose = {
        "You are no longer immune to the effects of steam.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
