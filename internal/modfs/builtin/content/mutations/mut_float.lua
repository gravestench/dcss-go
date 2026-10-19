-- mut float (MUT_FLOAT) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FLOAT",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "float",
    description = "You hover through the air, forever free from the surly bonds of earth.",
    -- These mut float descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You float through the air rather than walking.",
        "",
        "",
    },
    gain = {
        "You feel both weightless and legless.",
        "",
        "",
    },
    lose = {
        "You feel dragged down by the weight of the world.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
