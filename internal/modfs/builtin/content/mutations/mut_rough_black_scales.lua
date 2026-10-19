-- mut rough black scales (MUT_ROUGH_BLACK_SCALES) has up to 3 levels and
-- selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ROUGH_BLACK_SCALES",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "rough black scales",
    -- These mut rough black scales descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are partially covered in rough black scales. (AC +2, Dex -1)",
        "You are mostly covered in rough black scales. (AC +5, Dex -2)",
        "You are completely covered in rough black scales. (AC +8, Dex -3)",
    },
    gain = {
        "Rough black scales grow over part of your body.",
        "Rough black scales spread over more of your body.",
        "Rough black scales cover your body completely.",
    },
    lose = {
        "Your rough black scales disappear.",
        "Your rough black scales recede somewhat.",
        "Your rough black scales recede somewhat.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
