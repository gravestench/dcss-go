-- mut foul stench (MUT_FOUL_STENCH) has up to 3 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FOUL_STENCH",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "foul stench",
    description =
        "Foes who strike you in melee sometimes cause you to emit a cloud of foul\nmiasma," ..
        " slowing and severely poisoning those caught within. This mutation also\ngrants you" ..
        " immunity to miasma (from any source).",
    -- These mut foul stench descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You may rarely emit foul miasma when damaged in melee.",
        "You sometimes emit foul miasma when damaged in melee.",
        "You frequently emit foul miasma when damaged in melee.",
    },
    gain = {
        "You begin to emit a foul stench of rot and decay.",
        "Your foul stench grows more powerful.",
        "You begin to radiate miasma.",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
