-- mut forlorn (MUT_FORLORN) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FORLORN",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "forlorn",
    description = "You cannot, will not, and will never worship any god.",
    -- These mut forlorn descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You shall have no god before yourself.",
        "",
        "",
    },
    gain = {
        "You feel forlorn.",
        "",
        "",
    },
    lose = {
        "You feel more spiritual.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
