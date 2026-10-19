-- mut fumes (MUT_FUMES) has up to 2 levels and selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FUMES",
    status = "removed",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "fuming",
    -- These mut fumes descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You emit clouds of smoke.",
        "You frequently emit clouds of smoke.",
        "",
    },
    gain = {
        "You fume.",
        "You fume more.",
        "",
    },
    lose = {
        "You stop fuming.",
        "You fume less.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
