-- mut flame cloud immunity (MUT_FLAME_CLOUD_IMMUNITY) has up to 1 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FLAME_CLOUD_IMMUNITY",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "flame cloud immunity",
    description = "You are immune to clouds of flame.",
    -- These mut flame cloud immunity descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are immune to clouds of flame.",
        "",
        "",
    },
    gain = {
        "You feel less concerned about heat.",
        "",
        "",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
