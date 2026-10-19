-- mut conserve scrolls (MUT_CONSERVE_SCROLLS) has up to 1 levels and
-- selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CONSERVE_SCROLLS",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "conserve scrolls",
    -- These mut conserve scrolls descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are very good at protecting items from fire.",
        "",
        "",
    },
    gain = {
        "You feel less concerned about heat.",
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
