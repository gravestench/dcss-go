-- mut petrification resistance (MUT_PETRIFICATION_RESISTANCE) has up to 1
-- levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_PETRIFICATION_RESISTANCE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "petrification resistance",
    description = "You are immune to petrification.",
    -- These mut petrification resistance descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are immune to petrification.",
        "",
        "",
    },
    gain = {
        "Your body vibrates.",
        "",
        "",
    },
    lose = {
        "You briefly stop moving.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
