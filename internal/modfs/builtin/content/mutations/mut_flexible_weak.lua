-- mut flexible weak (MUT_FLEXIBLE_WEAK) has up to 3 levels and selection
-- weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FLEXIBLE_WEAK",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "flexible muscles",
    -- These mut flexible weak descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your muscles are flexible, but weak (Str -1, Dex +1).",
        "Your muscles are very flexible, but weak (Str -2, Dex +2).",
        "Your muscles are extremely flexible, but weak (Str -3, Dex +3).",
    },
    gain = {
        "Your muscles feel loose.",
        "Your muscles feel loose.",
        "Your muscles feel loose.",
    },
    lose = {
        "Your muscles feel sore.",
        "Your muscles feel sore.",
        "Your muscles feel sore.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
