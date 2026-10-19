-- mut heat resistance (MUT_HEAT_RESISTANCE) has up to 3 levels and selection
-- weight 4.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HEAT_RESISTANCE",
    status = "active",
    weight = 4,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "fire resistance",
    description =
        "You resist heat. Each level of this mutation reduces the amount of damage taken\nfrom" ..
        " fire.",
    -- These mut heat resistance descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your flesh is heat resistant. (rF+)",
        "Your flesh is very heat resistant. (rF++)",
        "Your flesh is almost immune to the effects of heat. (rF+++)",
    },
    gain = {
        "You feel resistant to heat.",
        "You feel more resistant to heat.",
        "You feel more resistant to heat.",
    },
    lose = {
        "You no longer feel heat resistant.",
        "You feel less heat resistant.",
        "You feel less heat resistant.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
