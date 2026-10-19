-- mut strong (MUT_STRONG) has up to 2 levels and selection weight 7.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STRONG",
    status = "active",
    weight = 7,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "strong",
    description =
        "Your muscles have grown unnaturally strong. Each level of this mutation provides\n+4" ..
        " Strength, but the extra muscles slow your movements and thoughts, giving -1 to\nboth" ..
        " your Intelligence and Dexterity for each level.",
    -- These mut strong descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "Your muscles are strong. (Str +4, Int/Dex -1)",
        "Your muscles are very strong. (Str +8, Int/Dex -2)",
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
