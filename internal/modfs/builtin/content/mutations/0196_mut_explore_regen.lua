-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2353
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_EXPLORE_REGEN",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "explore regen",
    description =
        "As you explore the dungeon, your wounds will heal and your magic will replenish.",
    have = {
        "You regain HP and MP as you explore.",
        "",
        "",
    },
    gain = {
        "You feel a fierce wanderlust.",
        "",
        "",
    },
    lose = {
        "You feel like a homebody.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
