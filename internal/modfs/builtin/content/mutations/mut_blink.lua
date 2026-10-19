-- mut blink (MUT_BLINK) has up to 1 levels and selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BLINK",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "blink",
    -- These mut blink descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You can translocate small distances at will.",
        "",
        "",
    },
    gain = {
        "You feel jittery.",
        "",
        "",
    },
    lose = {
        "You no longer feel jittery.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
