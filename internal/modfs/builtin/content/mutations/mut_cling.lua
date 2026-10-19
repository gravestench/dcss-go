-- mut cling (MUT_CLING) has up to 1 levels and selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CLING",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "cling",
    -- These mut cling descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You can cling to walls.",
        "",
        "",
    },
    gain = {
        "You feel sticky.",
        "",
        "",
    },
    lose = {
        "You feel slippery.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
