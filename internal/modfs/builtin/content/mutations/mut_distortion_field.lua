-- mut distortion field (MUT_DISTORTION_FIELD) has up to 3 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DISTORTION_FIELD",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "repulsion field",
    description =
        "You are surrounded by a repulsion field, providing a small amount of evasion.\nEach" ..
        " level of this mutation provides more EV. The third level of this mutation\nalso" ..
        " halves the accuracy of ranged attacks launched at you.",
    -- These mut distortion field descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are surrounded by a mild repulsion field. (EV +2)",
        "You are surrounded by a moderate repulsion field. (EV +3)",
        "You are surrounded by a strong repulsion field. (EV +4, RMsl)",
    },
    gain = {
        "You begin to radiate repulsive energy.",
        "Your repulsive radiation grows stronger.",
        "Your repulsive radiation grows stronger.",
    },
    lose = {
        "You feel less repulsive.",
        "You feel less repulsive.",
        "You feel less repulsive.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
