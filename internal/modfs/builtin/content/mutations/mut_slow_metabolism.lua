-- mut slow metabolism (MUT_SLOW_METABOLISM) has up to 2 levels and selection
-- weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SLOW_METABOLISM",
    status = "removed",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "slow metabolism",
    -- These mut slow metabolism descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have a slow metabolism.",
        "You need to consume almost no food.",
        "",
    },
    gain = {
        "Your metabolism slows.",
        "Your metabolism slows.",
        "",
    },
    lose = {
        "You feel a little hungry.",
        "You feel a little hungry.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
