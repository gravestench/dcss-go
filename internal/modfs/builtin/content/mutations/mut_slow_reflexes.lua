-- mut slow reflexes (MUT_SLOW_REFLEXES) has up to 3 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SLOW_REFLEXES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "reduced EV",
    description = "Your reflexes are slow, making it easier for foes to hit you.",
    -- These mut slow reflexes descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have somewhat slow reflexes. (EV -5)",
        "You have slow reflexes. (EV -10)",
        "You have very slow reflexes. (EV -15)",
    },
    gain = {
        "Your reflexes slow.",
        "Your reflexes slow further.",
        "Your reflexes slow further.",
    },
    lose = {
        "You reflexes return to normal.",
        "You reflexes speed back up.",
        "You reflexes speed back up.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
