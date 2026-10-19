-- mut weak (MUT_WEAK) has up to 2 levels and selection weight 8.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_WEAK",
    status = "active",
    weight = 8,
    max_level = 2,
    uses = {
        "bad",
        "xom",
    },
    form_based = false,
    short_description = "weak",
    description =
        "Your muscles have grown unnaturally weak. Each level of this mutation provides\n-2" ..
        " Strength.",
    -- These mut weak descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You are weak. (Str -2)",
        "You are very weak. (Str -4)",
        "",
    },
    gain = {
        "",
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
