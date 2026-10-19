-- mut negative energy resistance (MUT_NEGATIVE_ENERGY_RESISTANCE) has up to 3
-- levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NEGATIVE_ENERGY_RESISTANCE",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "negative energy resistance",
    description =
        "You resist negative energy. Each level of this mutation reduces the amount of\ndamage" ..
        " taken from negative energy, along with the amount that it drains your\nhealth.",
    -- These mut negative energy resistance descriptions are indexed by the
    -- player's effective mutation level.
    have = {
        "You resist negative energy. (rN+)",
        "You are quite resistant to negative energy. (rN++)",
        "You are immune to negative energy. (rN+++)",
    },
    gain = {
        "You feel resistant to negative energy.",
        "You feel more resistant to negative energy.",
        "You feel more resistant to negative energy.",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
