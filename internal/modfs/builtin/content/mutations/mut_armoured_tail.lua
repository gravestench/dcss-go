-- mut armoured tail (MUT_ARMOURED_TAIL) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ARMOURED_TAIL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "armoured tail",
    description =
        "You have a large armoured tail, allowing you to tail-slap foes when launching\nmelee" ..
        " attacks.",
    -- These mut armoured tail descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have a long armoured tail.",
        "",
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
