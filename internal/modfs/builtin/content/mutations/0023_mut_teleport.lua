-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:298
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TELEPORT",
    status = "active",
    weight = 3,
    max_level = 2,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "teleportitis",
    description =
        "You occasionally teleport across the level to hostile monsters. Each level of\nthis" ..
        " mutation increases the frequency with which this occurs.",
    have = {
        "You are occasionally teleported next to monsters.",
        "You are often teleported next to monsters.",
        "",
    },
    gain = {
        "You feel weirdly uncertain.",
        "You feel even more weirdly uncertain.",
        "",
    },
    lose = {
        "You feel stable.",
        "You feel stable.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
