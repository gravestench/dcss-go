-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2125
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_PAWS",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "stealthy paws",
    description =
        "When launching attacks on unaware or incapacitated enemies, you inflict extra\ndamage" ..
        " in the same way as a human with a short blade might.",
    have = {
        "Your paws help you pounce on unaware monsters.",
        "",
        "",
    },
    gain = {
        "",
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
