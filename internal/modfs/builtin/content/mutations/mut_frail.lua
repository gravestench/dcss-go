-- mut frail (MUT_FRAIL) has up to 3 levels and selection weight 10.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FRAIL",
    status = "active",
    weight = 10,
    max_level = 3,
    uses = {
        "bad",
        "xom",
    },
    form_based = false,
    short_description = "frail",
    description =
        "Your health is poor. Each level of this mutation worsens your health further\n(-10%" ..
        " HP).",
    -- These mut frail descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You are frail. (-10% HP)",
        "You are very frail. (-20% HP)",
        "You are extremely frail. (-30% HP)",
    },
    gain = {
        "You feel frail.",
        "You feel frail.",
        "You feel frail.",
    },
    lose = {
        "You feel robust.",
        "You feel robust.",
        "You feel robust.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
