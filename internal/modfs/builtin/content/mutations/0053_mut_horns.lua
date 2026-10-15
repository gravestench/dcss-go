-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:724
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HORNS",
    status = "active",
    weight = 7,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "horns",
    description =
        "You have horns on your head, allowing you to try to gore foes when launching\nmelee" ..
        " attacks, but preventing you from wearing helmets. Each level of this mutation" ..
        "\nincreases the damage of your gore attacks. The third level of this mutation" ..
        "\nprevents you from wearing any type of headgear.",
    have = {
        "You have a pair of small horns on your head.",
        "You have a pair of horns on your head.",
        "You have a pair of large horns on your head.",
    },
    gain = {
        "A pair of horns grows on your head!",
        "The horns on your head grow some more.",
        "The horns on your head grow some more.",
    },
    lose = {
        "The horns on your head shrink away.",
        "The horns on your head shrink a bit.",
        "The horns on your head shrink a bit.",
    },
    tile_id = "TILEG_MUT_HORNS",
}

register.definition(categories.MUTATIONS, definition)

return definition
