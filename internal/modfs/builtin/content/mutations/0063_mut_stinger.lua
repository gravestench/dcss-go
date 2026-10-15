-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:873
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STINGER",
    status = "active",
    weight = 8,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "stinger",
    description =
        "You have a venomous barb on the end of your tail, allowing you to sting foes\nwhen" ..
        " launching melee attacks. Each level of this mutation makes your stinger\nsharper," ..
        " longer, and stronger.",
    have = {
        "Your tail ends in a venomous barb.",
        "Your tail ends in a sharp venomous barb.",
        "Your tail ends in a wickedly sharp and venomous barb.",
    },
    gain = {
        "A venomous barb forms on the end of your tail.",
        "The barb on your tail looks sharper.",
        "The barb on your tail looks very sharp.",
    },
    lose = {
        "The barb on your tail disappears.",
        "The barb on your tail seems less sharp.",
        "The barb on your tail seems less sharp.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
