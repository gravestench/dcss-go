-- mut miasma immunity (MUT_MIASMA_IMMUNITY) has up to 1 levels and selection
-- weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MIASMA_IMMUNITY",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "miasma immunity",
    -- These mut miasma immunity descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are immune to miasma.",
        "",
        "",
    },
    gain = {
        "You feel immune to miasma.",
        "",
        "",
    },
    lose = {
        "You feel vulnerable to miasma.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
