-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1748
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SILENCE_AURA",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "aura of silence",
    description =
        "You are surrounded by an aura of silence. Those adjacent to you cannot make any" ..
        "\nsound. This prevents most forms of spellcasting and prayer, though demonic\nmagic," ..
        " being noiseless, is unaffected.",
    have = {
        "You are surrounded by an aura of silence.",
        "",
        "",
    },
    gain = {
        "An unnatural silence shrouds you.",
        "",
        "",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
