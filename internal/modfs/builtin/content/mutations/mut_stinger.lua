-- mut stinger (MUT_STINGER) has up to 3 levels and selection weight 8.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STINGER",
    status = "active",
    weight = 8,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "stinger",
    description =
        "You have a venomous barb on the end of your tail, allowing you to sting foes\nwhen" ..
        " launching melee attacks. Each level of this mutation makes your stinger\nsharper," ..
        " longer, and stronger.",
    -- These mut stinger descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your tail ends in a venomous barb.",
        "Your tail ends in a sharp venomous barb.",
        "Your tail ends in a wickedly sharp and venomous barb.",
    },
    gain = {
        "A venomous barb forms on the end of your tail.",
        "The barb on your tail looks sharper.",
        "The barb on your tail looks very sharp.",
    },
    lose = {
        "The barb on your tail disappears.",
        "The barb on your tail seems less sharp.",
        "The barb on your tail seems less sharp.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
