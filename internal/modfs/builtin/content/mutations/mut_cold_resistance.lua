-- mut cold resistance (MUT_COLD_RESISTANCE) has up to 3 levels and selection
-- weight 4.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_COLD_RESISTANCE",
    status = "active",
    weight = 4,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "cold resistance",
    description =
        "You resist cold. Each level of this mutation reduces the amount of damage taken\nfrom" ..
        " cold.",
    -- These mut cold resistance descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your flesh is cold resistant. (rC+)",
        "Your flesh is very cold resistant. (rC++)",
        "Your flesh is almost immune to the effects of cold. (rC+++)",
    },
    gain = {
        "You feel resistant to cold.",
        "You feel more resistant to cold.",
        "You feel more resistant to cold.",
    },
    lose = {
        "You no longer feel cold resistant.",
        "You feel less cold resistant.",
        "You feel less cold resistant.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
