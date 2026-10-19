-- mut low magic (MUT_LOW_MAGIC) has up to 3 levels and selection weight 9.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_LOW_MAGIC",
    status = "active",
    weight = 9,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "low MP",
    -- These mut low magic descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your magical capacity is low. (-10% MP)",
        "Your magical capacity is very low. (-20% MP)",
        "Your magical capacity is extremely low. (-30% MP)",
    },
    gain = {
        "You feel less energetic.",
        "You feel less energetic.",
        "You feel less energetic.",
    },
    lose = {
        "You feel more energetic.",
        "You feel more energetic.",
        "You feel more energetic.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
