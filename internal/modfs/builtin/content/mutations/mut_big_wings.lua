-- mut big wings (MUT_BIG_WINGS) has up to 1 levels and selection weight 4.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BIG_WINGS",
    status = "active",
    weight = 4,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "big wings",
    description = "You have big, strong wings, capable of bearing you through the air.",
    -- These mut big wings descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your large and strong wings let you fly.",
        "",
        "",
    },
    gain = {
        "Your wings grow larger and stronger.",
        "",
        "",
    },
    lose = {
        "Your wings shrivel and weaken.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
