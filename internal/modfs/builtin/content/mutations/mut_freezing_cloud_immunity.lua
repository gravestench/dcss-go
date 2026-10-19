-- mut freezing cloud immunity (MUT_FREEZING_CLOUD_IMMUNITY) has up to 1
-- levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FREEZING_CLOUD_IMMUNITY",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "freezing cloud immunity",
    description = "You are immune to freezing clouds.",
    -- These mut freezing cloud immunity descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are immune to freezing clouds.",
        "",
        "",
    },
    gain = {
        "You feel less concerned about cold.",
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
