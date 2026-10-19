-- mut strong stiff (MUT_STRONG_STIFF) has up to 3 levels and selection weight
-- 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STRONG_STIFF",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "stiff muscles",
    -- These mut strong stiff descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your muscles are strong, but stiff. (Str +1, Dex -1)",
        "Your muscles are very strong, but stiff. (Str +2, Dex -2)",
        "Your muscles are extremely strong, but stiff. (Str +3, Dex -3)",
    },
    gain = {
        "Your muscles feel sore.",
        "Your muscles feel sore.",
        "Your muscles feel sore.",
    },
    lose = {
        "Your muscles feel loose.",
        "Your muscles feel loose.",
        "Your muscles feel loose.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
