-- mut breathe flames (MUT_BREATHE_FLAMES) has up to 3 levels and selection
-- weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BREATHE_FLAMES",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "breathe flames",
    -- These mut breathe flames descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You can breathe flames.",
        "You can breathe fire.",
        "You can breathe blasts of fire.",
    },
    gain = {
        "Your throat feels hot.",
        "Your throat feels hot.",
        "Your throat feels hot.",
    },
    lose = {
        "A chill runs up and down your throat.",
        "A chill runs up and down your throat.",
        "A chill runs up and down your throat.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
