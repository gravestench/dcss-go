-- mut inexperienced (MUT_INEXPERIENCED) has up to 3 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_INEXPERIENCED",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "inexperienced",
    description = "You are inexperienced, and unable to fully gain 27 levels.",
    -- These mut inexperienced descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are somewhat inexperienced. (-1 XL)",
        "You are inexperienced. (-2 XL)",
        "You are extremely inexperienced. (-3 XL)",
    },
    gain = {
        "You feel less experienced.",
        "You feel less experienced.",
        "You feel less experienced.",
    },
    lose = {
        "You regain all your potential.",
        "You regain some potential.",
        "You regain some potential.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
