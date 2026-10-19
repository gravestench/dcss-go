-- mut jump (MUT_JUMP) has up to 3 levels and selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_JUMP",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "jump",
    -- These mut jump descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You can jump attack at a short distance.",
        "You can jump attack at a medium distance.",
        "You can jump attack at a long distance.",
    },
    gain = {
        "You feel more sure on your feet.",
        "You feel more sure on your feet.",
        "You feel more sure on your feet.",
    },
    lose = {
        "You feel less sure on your feet.",
        "You feel less sure on your feet.",
        "You feel less sure on your feet.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
