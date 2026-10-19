-- mut spit poison (MUT_SPIT_POISON) has up to 2 levels and selection weight
-- 8.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SPIT_POISON",
    status = "active",
    weight = 8,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "spit poison",
    description =
        "You can spit poison with <input>$cmd[CMD_USE_ABILITY]</input>. The second level\nof" ..
        " this mutation intensifies the poison from a single glob into a large cloud.",
    -- These mut spit poison descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You can spit poison.",
        "You can exhale a cloud of poison.",
        "",
    },
    gain = {
        "There is a nasty taste in your mouth for a moment.",
        "There is a nasty taste in your mouth for a moment.",
        "",
    },
    lose = {
        "You feel an ache in your throat.",
        "You feel an ache in your throat.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
