-- mut scream (MUT_SCREAM) has up to 2 levels and selection weight 6.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
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
    -- These mut scream descriptions are indexed by the player's effective mutation
    -- level.
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
