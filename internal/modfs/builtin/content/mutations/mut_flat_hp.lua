-- mut flat hp (MUT_FLAT_HP) has up to 3 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FLAT_HP",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "extra vitality",
    description =
        "You are built differently from most species, making you slightly harder to kill.\nEach" ..
        " level of this mutation increases your maximum health by 4 points.",
    -- These mut flat hp descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have superior vitality. (+4 MHP)",
        "You have much superior vitality. (+8 MHP)",
        "You have exceptionally superior vitality. (+12 MHP)",
    },
    gain = {
        "You feel less vital.",
        "You feel less vital.",
        "You feel less vital.",
    },
    lose = {
        "You feel more vital.",
        "You feel more vital.",
        "You feel more vital.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
