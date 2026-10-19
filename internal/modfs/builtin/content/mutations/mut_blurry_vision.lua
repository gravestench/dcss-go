-- mut blurry vision (MUT_BLURRY_VISION) has up to 3 levels and selection
-- weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BLURRY_VISION",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "blurry vision",
    -- These mut blurry vision descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Scrolls take you a little longer to read.",
        "Scrolls take you longer to read.",
        "Scrolls take you much longer to read.",
    },
    gain = {
        "Your vision blurs.",
        "Your vision blurs.",
        "Your vision blurs.",
    },
    lose = {
        "Your vision sharpens.",
        "Your vision sharpens a little.",
        "Your vision sharpens a little.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
