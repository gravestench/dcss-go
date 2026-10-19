-- mut carnivorous (MUT_CARNIVOROUS) has up to 1 levels and selection weight
-- 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CARNIVOROUS",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "carnivore",
    -- These mut carnivorous descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are carnivorous and can eat meat at any time.",
        "",
        "",
    },
    gain = {
        "You hunger for flesh.",
        "",
        "",
    },
    lose = {
        "You feel able to eat a more balanced diet.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
