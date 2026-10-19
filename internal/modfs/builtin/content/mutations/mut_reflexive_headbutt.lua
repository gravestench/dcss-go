-- mut reflexive headbutt (MUT_REFLEXIVE_HEADBUTT) has up to 1 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
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
    -- These mut reflexive headbutt descriptions are indexed by the player's
    -- effective mutation level.
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
