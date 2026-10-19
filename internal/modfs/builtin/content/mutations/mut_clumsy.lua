-- mut clumsy (MUT_CLUMSY) has up to 2 levels and selection weight 8.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CLUMSY",
    status = "active",
    weight = 8,
    max_level = 2,
    uses = {
        "bad",
        "xom",
    },
    form_based = false,
    short_description = "clumsy",
    description =
        "Your reflexes have become unnaturally clumsy. Each level of this mutation\nprovides -2" ..
        " Dexterity.",
    -- These mut clumsy descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You are clumsy. (Dex -2)",
        "You are very clumsy. (Dex -4)",
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
