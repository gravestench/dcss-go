-- mut paws (MUT_PAWS) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_PAWS",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "stealthy paws",
    description =
        "When launching attacks on unaware or incapacitated enemies, you inflict extra\ndamage" ..
        " in the same way as a human with a short blade might.",
    -- These mut paws descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "Your paws help you pounce on unaware monsters.",
        "",
        "",
    },
    gain = {
        "",
        "",
        "",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
