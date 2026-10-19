-- mut high magic (MUT_HIGH_MAGIC) has up to 3 levels and selection weight 2.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HIGH_MAGIC",
    status = "active",
    weight = 2,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "high MP",
    -- These mut high magic descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have an increased reservoir of magic. (+10% MP)",
        "You have a considerably increased reservoir of magic. (+20% MP)",
        "You have a greatly increased reservoir of magic. (+30% MP)",
    },
    gain = {
        "You feel more energetic.",
        "You feel more energetic.",
        "You feel more energetic.",
    },
    lose = {
        "You feel less energetic.",
        "You feel less energetic.",
        "You feel less energetic.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
