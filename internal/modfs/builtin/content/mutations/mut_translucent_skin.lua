-- mut translucent skin (MUT_TRANSLUCENT_SKIN) has up to 3 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TRANSLUCENT_SKIN",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "translucent skin",
    description =
        "Your skin is transparent, improving your stealth and reducing the accuracy of\nyour" ..
        " foes' attacks against you. Each level of this mutation reduces your foes'\naccuracy" ..
        " further.",
    -- These mut translucent skin descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "Your translucent skin slightly reduces your foes' accuracy. (Stealth+)",
        "Your translucent skin reduces your foes' accuracy. (Stealth+)",
        "Your transparent skin significantly reduces your foes' accuracy. (Stealth+)",
    },
    gain = {
        "Your skin becomes partially translucent.",
        "Your skin becomes more translucent.",
        "Your skin becomes completely transparent.",
    },
    lose = {
        "Your skin returns to its normal opacity.",
        "Your skin's translucency fades.",
        "Your skin's transparency fades.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
