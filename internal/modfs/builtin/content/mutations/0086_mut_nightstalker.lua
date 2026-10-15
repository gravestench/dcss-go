-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1151
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NIGHTSTALKER",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "nightstalker",
    description =
        "You are attuned to the shadows, reducing the distance that you can see or be\nseen" ..
        " from.",
    have = {
        "You are slightly more attuned to the shadows.",
        "You are significantly more attuned to the shadows.",
        "You are completely attuned to the shadows.",
    },
    gain = {
        "You slip into the darkness of the dungeon.",
        "You slip further into the darkness.",
        "You are surrounded by darkness.",
    },
    lose = {
        "Your affinity for the darkness vanishes.",
        "Your affinity for the darkness weakens.",
        "Your affinity for the darkness weakens.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
