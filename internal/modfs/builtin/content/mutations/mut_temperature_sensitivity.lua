-- mut temperature sensitivity (MUT_TEMPERATURE_SENSITIVITY) has up to 1
-- levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TEMPERATURE_SENSITIVITY",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "temperature sensitive",
    description =
        "You are vulnerable to both cold and fire, and you take more damage from those\neffects.",
    -- These mut temperature sensitivity descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are sensitive to extremes of temperature. (rF-, rC-)",
        "",
        "",
    },
    gain = {
        "You feel sensitive to extremes of temperature.",
        "",
        "",
    },
    lose = {
        "You no longer feel sensitive to extremes of temperature",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
