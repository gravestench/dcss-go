-- mut hp casting (MUT_HP_CASTING) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HP_CASTING",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "HP casting",
    -- These mut hp casting descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your magical power is your life essence.",
        "",
        "",
    },
    gain = {
        "Your magical power and health merge together.",
        "",
        "",
    },
    lose = {
        "Your life and magic unlink.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
