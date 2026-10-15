-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1773
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_WORD_OF_CHAOS",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "word of chaos",
    description = "You can speak a Word of Chaos with <input>$cmd[CMD_USE_ABILITY]</input>.",
    have = {
        "You can speak a Word of Chaos.",
        "",
        "",
    },
    gain = {
        "Your tongue twists.",
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
