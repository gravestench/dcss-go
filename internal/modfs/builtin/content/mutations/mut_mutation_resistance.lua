-- mut mutation resistance (MUT_MUTATION_RESISTANCE) has up to 3 levels and
-- selection weight 4.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MUTATION_RESISTANCE",
    status = "active",
    weight = 4,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "mutation resistance",
    description =
        "Your genetic code is unusually stable, making it less likely that you will be\nmutated" ..
        " (or have existing mutations removed). Each level of this mutation makes\nyou more" ..
        " resistant.",
    -- These mut mutation resistance descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are somewhat resistant to further mutation.",
        "You are somewhat resistant to both further mutation and mutation removal.",
        "You are almost entirely resistant to further mutation and mutation removal.",
    },
    gain = {
        "You feel genetically stable.",
        "You feel genetically stable.",
        "You feel genetically immutable.",
    },
    lose = {
        "You feel genetically unstable.",
        "You feel genetically unstable.",
        "You feel genetically unstable.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
