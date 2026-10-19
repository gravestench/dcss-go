-- mut food jelly (MUT_FOOD_JELLY) has up to 1 levels and selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FOOD_JELLY",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "spawn jellies when eating",
    -- These mut food jelly descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You occasionally spawn a jelly by eating.",
        "",
        "",
    },
    gain = {
        "You feel more connected to the slimes.",
        "",
        "",
    },
    lose = {
        "Your connection to the slimes vanishes.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
