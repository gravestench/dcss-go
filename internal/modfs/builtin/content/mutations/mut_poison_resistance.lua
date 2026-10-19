-- mut poison resistance (MUT_POISON_RESISTANCE) has up to 1 levels and
-- selection weight 4.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_POISON_RESISTANCE",
    status = "active",
    weight = 4,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "poison resistance",
    description =
        "You resist poisons, toxins and other contaminants. This does not confer\nfull" ..
        " immunity, but reduces your chances of being affected to roughly\none-third what it" ..
        " would be otherwise.",
    -- These mut poison resistance descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "Your system is resistant to poisons. (rPois)",
        "",
        "",
    },
    gain = {
        "You feel resistant to poisons.",
        "",
        "",
    },
    lose = {
        "You feel less resistant to poisons.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
