-- mut word of chaos (MUT_WORD_OF_CHAOS) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_WORD_OF_CHAOS",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "word of chaos",
    description = "You can speak a Word of Chaos with <input>$cmd[CMD_USE_ABILITY]</input>.",
    -- These mut word of chaos descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You can speak a Word of Chaos.",
        "",
        "",
    },
    gain = {
        "Your tongue twists.",
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
