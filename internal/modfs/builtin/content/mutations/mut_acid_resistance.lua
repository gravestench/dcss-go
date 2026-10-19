-- mut acid resistance (MUT_ACID_RESISTANCE) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ACID_RESISTANCE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "acid resistance",
    description =
        "You resist acid (rCorr), taking less damage from it. You are also less likely to" ..
        "\nbecome corroded.",
    -- These mut acid resistance descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are resistant to acid. (rCorr)",
        "",
        "",
    },
    gain = {
        "You feel resistant to acid.",
        "",
        "",
    },
    lose = {
        "You feel less resistant to acid.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
