-- mut unskilled (MUT_UNSKILLED) has up to 3 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_UNSKILLED",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "unskilled",
    description =
        "It takes you more experience to improve your skills. Each level of this\nsacrifice" ..
        " makes your skills cost even more.",
    -- These mut unskilled descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are somewhat unskilled. (-1 Apt)",
        "You are unskilled. (-2 Apt)",
        "You are extremely unskilled. (-3 Apt)",
    },
    gain = {
        "You feel less skilled.",
        "You feel less skilled.",
        "You feel less skilled.",
    },
    lose = {
        "You regain all your skill.",
        "You regain some skill.",
        "You regain some skill.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
