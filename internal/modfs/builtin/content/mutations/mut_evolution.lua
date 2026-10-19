-- mut evolution (MUT_EVOLUTION) has up to 2 levels and selection weight 4.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_EVOLUTION",
    status = "active",
    weight = 4,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "evolution",
    description =
        "As you gain experience, your body's hidden potential will express itself in the\nform" ..
        " of new beneficial mutations.",
    -- These mut evolution descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have hidden genetic potential.",
        "You have great hidden genetic potential.",
        "",
    },
    gain = {
        "You feel a hidden potential growing inside you.",
        "Your hidden genetic potential grows.",
        "",
    },
    lose = {
        "You no longer feel a hidden potential within.",
        "Your hidden genetic potential wanes.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
