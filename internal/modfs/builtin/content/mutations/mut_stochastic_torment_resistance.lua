-- mut stochastic torment resistance (MUT_STOCHASTIC_TORMENT_RESISTANCE) has
-- up to 1 levels and selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STOCHASTIC_TORMENT_RESISTANCE",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "removed torment resistance",
    -- These mut stochastic torment resistance descriptions are indexed by the
    -- player's effective mutation level.
    have = {
        "You are somewhat able to resist unholy torments.",
        "",
        "",
    },
    gain = {
        "You feel a strange anaesthesia.",
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
