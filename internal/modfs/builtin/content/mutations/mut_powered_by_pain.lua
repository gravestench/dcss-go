-- mut powered by pain (MUT_POWERED_BY_PAIN) has up to 3 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_POWERED_BY_PAIN",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "powered by pain",
    description =
        "When you are harmed, you sometimes gain power, refilling your magical reservoir\nor" ..
        " granting you temporary agility or might. Each level of this mutation\nincreases the" ..
        " magnitude of this effect.",
    -- These mut powered by pain descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You sometimes gain a little power by taking damage.",
        "You sometimes gain power by taking damage.",
        "You are powered by pain.",
    },
    gain = {
        "You feel energised by your suffering.",
        "You feel even more energised by your suffering.",
        "You feel completely energised by your suffering.",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
