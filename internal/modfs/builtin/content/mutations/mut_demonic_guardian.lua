-- mut demonic guardian (MUT_DEMONIC_GUARDIAN) has up to 3 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DEMONIC_GUARDIAN",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "demonic guardian",
    description =
        "When you are harmed, there is a chance that a demonic guardian will rush to aid\nyou." ..
        " The greater the damage done and the closer you are to death, the greater\nthe odds." ..
        " Each level of this mutation increases the strength of your guardians.",
    -- These mut demonic guardian descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "A weak demonic guardian rushes to your aid.",
        "A demonic guardian rushes to your aid.",
        "A powerful demonic guardian rushes to your aid.",
    },
    gain = {
        "You feel the presence of a demonic guardian.",
        "Your guardian grows in power.",
        "Your guardian grows in power.",
    },
    lose = {
        "Your demonic guardian is gone.",
        "Your demonic guardian is weakened.",
        "Your demonic guardian is weakened.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
