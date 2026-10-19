-- mut sturdy frame (MUT_STURDY_FRAME) has up to 3 levels and selection weight
-- 2.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STURDY_FRAME",
    status = "active",
    weight = 2,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "sturdy frame",
    description =
        "Your movements are less encumbered by armour, mitigating penalties to spell\nsuccess" ..
        " and accuracy. Each level of this mutation reduces armour ER by 2.",
    -- These mut sturdy frame descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your movements are slightly less encumbered by armour. (ER -2)",
        "Your movements are less encumbered by armour. (ER -4)",
        "Your movements are significantly less encumbered by armour. (ER -6)",
    },
    gain = {
        "You feel less encumbered by your armour.",
        "You feel less encumbered by your armour.",
        "You feel less encumbered by your armour.",
    },
    lose = {
        "You feel more encumbered by your armour.",
        "You feel more encumbered by your armour.",
        "You feel more encumbered by your armour.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
