-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2189
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_REFLEXIVE_HEADBUTT",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "retaliatory headbutt",
    description =
        "When a foe misses you in melee, you may reflexively retaliate, attempting to\ngore" ..
        " your attacker with your horns.",
    have = {
        "You reflexively headbutt those who attack you in melee.",
        "",
        "",
    },
    gain = {
        "Your retaliatory reflexes feel sharp.",
        "",
        "",
    },
    lose = {
        "Your retaliatory reflexes feel dull.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
