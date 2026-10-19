-- mut regeneration (MUT_REGENERATION) has up to 3 levels and selection weight
-- 2.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_REGENERATION",
    status = "active",
    weight = 2,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "regeneration",
    description =
        "You heal quickly. Each level of this mutation increases the rate at which you\nheal.",
    -- These mut regeneration descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your natural rate of healing is unusually fast.",
        "You heal very quickly.",
        "You regenerate.",
    },
    gain = {
        "You begin to heal more quickly.",
        "You begin to heal more quickly.",
        "You begin to regenerate.",
    },
    lose = {
        "Your rate of healing slows.",
        "Your rate of healing slows.",
        "Your rate of healing slows.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
