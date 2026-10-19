-- mut robust (MUT_ROBUST) has up to 3 levels and selection weight 5.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ROBUST",
    status = "active",
    weight = 5,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "robust",
    description =
        "You can take a beating. Each level of this mutation improves your health\nfurther" ..
        " (+10% HP).",
    -- These mut robust descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You are robust. (+10% HP)",
        "You are very robust. (+20% HP)",
        "You are extremely robust. (+30% HP)",
    },
    gain = {
        "You feel robust.",
        "You feel robust.",
        "You feel robust.",
    },
    lose = {
        "You feel frail.",
        "You feel frail.",
        "You feel frail.",
    },
    tile_id = "TILEG_MUT_ROBUST",
}

register.definition(categories.MUTATIONS, definition)

return definition
