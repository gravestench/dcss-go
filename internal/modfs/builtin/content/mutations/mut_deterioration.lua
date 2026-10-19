-- mut deterioration (MUT_DETERIORATION) has up to 2 levels and selection
-- weight 10.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DETERIORATION",
    status = "active",
    weight = 10,
    max_level = 2,
    uses = {
        "bad",
        "xom",
    },
    form_based = false,
    short_description = "deterioration",
    description =
        "When injured, your body sometimes deteriorates, temporarily reducing your\nattributes." ..
        " The second level of this mutation makes this happen more often.",
    -- These mut deterioration descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your body sometimes deteriorates upon taking damage.",
        "Your body often deteriorates upon taking damage.",
        "",
    },
    gain = {
        "You feel yourself wasting away.",
        "You feel your body start to fall apart.",
        "",
    },
    lose = {
        "You feel healthier.",
        "You feel a little healthier.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
