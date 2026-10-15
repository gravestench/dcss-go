-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1089
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_PASSIVE_MAPPING",
    status = "active",
    weight = 3,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "sense surroundings",
    description =
        "You have a second sense for the dungeon, allowing you to sense terrain you\nhaven't" ..
        " yet seen. Each level of this mutation allows you to sense more and\nmore thoroughly.",
    have = {
        "You passively map a small area around you.",
        "You passively map the area around you.",
        "You passively map a large area around you.",
    },
    gain = {
        "You feel a strange attunement to the structure of the dungeons.",
        "Your attunement to dungeon structure grows.",
        "Your attunement to dungeon structure grows further.",
    },
    lose = {
        "You feel slightly disoriented.",
        "You feel slightly disoriented.",
        "You feel slightly disoriented.",
    },
    tile_id = "TILEG_MUT_PASSIVE_MAPPING",
}

register.definition(categories.MUTATIONS, definition)

return definition
