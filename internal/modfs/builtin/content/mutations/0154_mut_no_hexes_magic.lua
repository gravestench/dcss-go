-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1977
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_HEXES_MAGIC",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no hexes magic",
    description = "Your Hexes skill is 0 and you cannot train the skill.",
    have = {
        "You cannot study or cast Hexes magic.",
        "",
        "",
    },
    gain = {
        "You can no longer study or cast Hexes magic.",
        "",
        "",
    },
    lose = {
        "You can once more study and cast Hexes magic.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
