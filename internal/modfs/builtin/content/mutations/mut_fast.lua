-- mut fast (MUT_FAST) has up to 3 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FAST",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "speed",
    description =
        "You cover ground quickly - moving to new positions takes you less time. This\nhas no" ..
        " effect on other types of actions, like attacking or casting spells.\nEach level of" ..
        " this mutation makes you move faster.",
    -- These mut fast descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You cover ground quickly. (Speed+)",
        "You cover ground very quickly. (Speed++)",
        "You cover ground extremely quickly. (Speed+++)",
    },
    gain = {
        "You feel quick.",
        "You feel quick.",
        "You feel quick.",
    },
    lose = {
        "You feel sluggish.",
        "You feel sluggish.",
        "You feel sluggish.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
