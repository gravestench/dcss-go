-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:383
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SPIT_POISON",
    status = "active",
    weight = 8,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "spit poison",
    description =
        "You can spit poison with <input>$cmd[CMD_USE_ABILITY]</input>. The second level\nof" ..
        " this mutation intensifies the poison from a single glob into a large cloud.",
    have = {
        "You can spit poison.",
        "You can exhale a cloud of poison.",
        "",
    },
    gain = {
        "There is a nasty taste in your mouth for a moment.",
        "There is a nasty taste in your mouth for a moment.",
        "",
    },
    lose = {
        "You feel an ache in your throat.",
        "You feel an ache in your throat.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
