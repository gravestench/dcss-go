-- mut big brain (MUT_BIG_BRAIN) has up to 3 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BIG_BRAIN",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "big brain",
    description =
        "What's up? You have a big brain. Each level of this mutation provides +2" ..
        "\nIntelligence. The third level of this mutation also makes you less likely to" ..
        "\nmiscast spells.",
    -- These mut big brain descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have an unusually large brain. (Int +2)",
        "You have an extremely huge brain. (Int +4)",
        "You have an absolutely massive brain. (Int +6, Wiz)",
    },
    gain = {
        "Your brain expands.",
        "Your brain expands.",
        "Your brain expands to incredible size.",
    },
    lose = {
        "Your brain returns to normal size.",
        "Your brain shrinks.",
        "Your brain shrinks.",
    },
    tile_id = "TILEG_MUT_BIG_BRAIN",
}

register.definition(categories.MUTATIONS, definition)

return definition
