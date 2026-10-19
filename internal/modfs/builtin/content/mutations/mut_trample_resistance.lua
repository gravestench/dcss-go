-- mut trample resistance (MUT_TRAMPLE_RESISTANCE) has up to 1 levels and
-- selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TRAMPLE_RESISTANCE",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "trample resistance",
    -- These mut trample resistance descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are resistant to trampling.",
        "",
        "",
    },
    gain = {
        "You feel steady.",
        "",
        "",
    },
    lose = {
        "You feel unsteady.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
