-- mut slow (MUT_SLOW) has up to 3 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SLOW",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = true,
    short_description = "slowness",
    description =
        "You cover ground slowly - moving to new positions takes you more time. This\nhas no" ..
        " effect on other types of actions, like attacking or casting spells.\nEach level of" ..
        " this mutation makes you move slower.",
    -- These mut slow descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You cover ground slowly.",
        "You cover ground very slowly.",
        "You cover ground extremely slowly.",
    },
    gain = {
        "You feel sluggish.",
        "You feel sluggish.",
        "You feel sluggish.",
    },
    lose = {
        "You feel quick.",
        "You feel quick.",
        "You feel quick.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
