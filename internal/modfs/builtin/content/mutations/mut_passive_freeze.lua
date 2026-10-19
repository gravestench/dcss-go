-- mut passive freeze (MUT_PASSIVE_FREEZE) has up to 1 levels and selection
-- weight 1.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_PASSIVE_FREEZE",
    status = "active",
    weight = 1,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "passive freeze",
    description =
        "Foes who strike you in melee will be frozen, taking damage. This effect is\nguaranteed" ..
        " to trigger if your foe does any damage.",
    -- These mut passive freeze descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "A frigid envelope surrounds you and freezes all who hurt you.",
        "",
        "",
    },
    gain = {
        "Your skin feels very cold.",
        "",
        "",
    },
    lose = {
        "Your skin warms up.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
