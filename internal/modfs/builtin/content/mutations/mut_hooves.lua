-- mut hooves (MUT_HOOVES) has up to 3 levels and selection weight 5.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HOOVES",
    status = "active",
    weight = 5,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "hooves",
    description =
        "You have hooves, allowing you to kick foes when launching melee attacks if you\naren't" ..
        " wearing boots. Each level of this mutation makes your hooves harder and\nstronger." ..
        " The third level of this mutation prevents you from wearing boots.",
    -- These mut hooves descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You have large cloven feet.",
        "You have hoof-like feet.",
        "You have hooves in place of feet.",
    },
    gain = {
        "Your feet thicken and deform.",
        "Your feet thicken and deform.",
        "Your feet have mutated into hooves.",
    },
    lose = {
        "Your hooves expand and flesh out into feet!",
        "Your hooves look more like feet.",
        "Your hooves look more like feet.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
