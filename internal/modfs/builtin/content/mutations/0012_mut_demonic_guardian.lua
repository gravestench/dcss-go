-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:169
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
