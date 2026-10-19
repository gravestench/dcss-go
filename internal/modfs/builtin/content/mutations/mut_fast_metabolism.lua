-- mut fast metabolism (MUT_FAST_METABOLISM) has up to 3 levels and selection
-- weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FAST_METABOLISM",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "fast metabolism",
    -- These mut fast metabolism descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have a fast metabolism.",
        "You have a very fast metabolism.",
        "Your metabolism is lightning-fast.",
    },
    gain = {
        "You feel a little hungry.",
        "You feel a little hungry.",
        "You feel a little hungry.",
    },
    lose = {
        "Your metabolism slows.",
        "Your metabolism slows.",
        "Your metabolism slows.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
