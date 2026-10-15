-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2157
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STRONG_NOSE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "strong nose",
    description =
        "You have a powerful nose adapted to the Dungeon's scents, allowing you to\ndetect" ..
        " where treasures lay hidden. As you explore the dungeon, nearby item\nlocations that" ..
        " you cannot directly see will gain a marker for\nas-yet-undiscovered items.",
    have = {
        "Your uncanny sense of smell can sniff out nearby items.",
        "",
        "",
    },
    gain = {
        "Your sense of smell grows stronger.",
        "",
        "",
    },
    lose = {
        "Your sense of smell gets weaker.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
