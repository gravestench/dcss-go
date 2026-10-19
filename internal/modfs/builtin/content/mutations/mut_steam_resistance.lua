-- mut steam resistance (MUT_STEAM_RESISTANCE) has up to 1 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STEAM_RESISTANCE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "steam resistance",
    description = "You are immune to the damage from steam breath and steam clouds.",
    -- These mut steam resistance descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are immune to the effects of steam.",
        "",
        "",
    },
    gain = {
        "You are now immune to the effects of steam.",
        "",
        "",
    },
    lose = {
        "You are no longer immune to the effects of steam.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
