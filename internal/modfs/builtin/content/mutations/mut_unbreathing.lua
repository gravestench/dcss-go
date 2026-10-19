-- mut unbreathing (MUT_UNBREATHING) has up to 2 levels and selection weight
-- 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_UNBREATHING",
    status = "removed",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "unbreathing",
    -- These mut unbreathing descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You can survive without breathing.",
        "You can survive without breathing, even under water.",
        "",
    },
    gain = {
        "You feel breathless.",
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
