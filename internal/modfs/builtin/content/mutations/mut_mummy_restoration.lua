-- mut mummy restoration (MUT_MUMMY_RESTORATION) has up to 1 levels and
-- selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MUMMY_RESTORATION",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "restore body",
    -- These mut mummy restoration descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You can restore your body by infusing magical energy.",
        "",
        "",
    },
    gain = {
        "You can now infuse your body with magic to restore decomposition.",
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
