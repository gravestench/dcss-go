-- mut cold blooded (MUT_COLD_BLOODED) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_COLD_BLOODED",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = true,
    short_description = "cold-blooded",
    description =
        "You are endothermic. When struck by a cold attack, you may be slowed until your\nblood" ..
        " warms again.",
    -- These mut cold blooded descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are cold-blooded and may be slowed by cold attacks.",
        "",
        "",
    },
    gain = {
        "You feel cold-blooded.",
        "",
        "",
    },
    lose = {
        "You feel warm-blooded.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
