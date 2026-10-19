-- mut conserve potions (MUT_CONSERVE_POTIONS) has up to 1 levels and
-- selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CONSERVE_POTIONS",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "conserve potions",
    -- These mut conserve potions descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are very good at protecting items from cold.",
        "",
        "",
    },
    gain = {
        "You feel less concerned about cold.",
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
