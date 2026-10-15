-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:559
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
