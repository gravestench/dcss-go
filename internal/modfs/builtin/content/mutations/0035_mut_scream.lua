-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:473
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SCREAM",
    status = "active",
    weight = 6,
    max_level = 2,
    uses = {
        "bad",
        "xom",
    },
    form_based = false,
    short_description = "screaming",
    description =
        "You are sometimes seized by an uncontrollable urge to scream at foes when they\nfirst" ..
        " come into sight. All of your shouts are also louder than usual. The\nsecond level of" ..
        " this mutation makes this urge harder to resist and makes your\nshouts even louder.",
    have = {
        "You occasionally shout uncontrollably at your foes.",
        "You frequently scream uncontrollably at your foes.",
        "",
    },
    gain = {
        "You feel the urge to shout.",
        "You feel a strong urge to scream.",
        "",
    },
    lose = {
        "Your urge to shout disappears.",
        "Your urge to scream lessens.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
