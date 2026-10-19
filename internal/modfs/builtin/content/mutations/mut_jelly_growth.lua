-- mut jelly growth (MUT_JELLY_GROWTH) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_JELLY_GROWTH",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "jelly sensing items",
    description = "You have a small jelly attached to you that senses nearby items.",
    -- These mut jelly growth descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have a small jelly attached to you that senses nearby items.",
        "",
        "",
    },
    gain = {
        "Your body partially splits into a small jelly.",
        "",
        "",
    },
    lose = {
        "The jelly growth is reabsorbed into your body.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
