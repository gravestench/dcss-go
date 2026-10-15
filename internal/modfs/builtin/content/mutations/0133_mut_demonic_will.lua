-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1781
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DEMONIC_WILL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "demonic willpower",
    description =
        "Your willpower has a will of its own, sometimes injuring those who attempt to\nhex" ..
        " you. This mutation also bolsters your Willpower.",
    have = {
        "You punish those that try to bend your will. (Will+)",
        "",
        "",
    },
    gain = {
        "You feel wilful.",
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
