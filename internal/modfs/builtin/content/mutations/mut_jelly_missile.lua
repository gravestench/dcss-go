-- mut jelly missile (MUT_JELLY_MISSILE) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_JELLY_MISSILE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "jelly absorbing missiles",
    description =
        "When struck by a missile (such as an arrow or crossbow bolt), a jelly on your\nbody" ..
        " may eat it, healing you somewhat.",
    -- These mut jelly missile descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have a small jelly attached to you that may absorb projectiles.",
        "",
        "",
    },
    gain = {
        "Your body partially splits into a small jelly.",
        "",
        "",
    },
    lose = {
        "The jelly growth is reabsorbed into your body.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
