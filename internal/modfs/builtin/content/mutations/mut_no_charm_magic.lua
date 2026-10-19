-- mut no charm magic (MUT_NO_CHARM_MAGIC) has up to 1 levels and selection
-- weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_CHARM_MAGIC",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no charms magic",
    -- These mut no charm magic descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You cannot study or cast removed Charms magic.",
        "",
        "",
    },
    gain = {
        "You can no longer study or cast Charms magic.",
        "",
        "",
    },
    lose = {
        "You can once more study and cast Charms magic.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
