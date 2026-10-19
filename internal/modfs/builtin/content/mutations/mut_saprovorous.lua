-- mut saprovorous (MUT_SAPROVOROUS) has up to 3 levels and selection weight
-- 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SAPROVOROUS",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "saprovore",
    -- These mut saprovorous descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You can tolerate rotten meat.",
        "You can eat rotten meat.",
        "You thrive on rotten meat.",
    },
    gain = {
        "You hunger for rotting flesh.",
        "You hunger for rotting flesh.",
        "You hunger for rotting flesh.",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
