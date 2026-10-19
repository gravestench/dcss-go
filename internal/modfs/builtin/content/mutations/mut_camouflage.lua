-- mut camouflage (MUT_CAMOUFLAGE) has up to 3 levels and selection weight 1.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CAMOUFLAGE",
    status = "active",
    weight = 1,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "camouflage",
    description =
        "Your skin changes colour to match your surroundings. Each level of this\nmutation" ..
        " provides Stealth+.",
    -- These mut camouflage descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your skin changes colour to match your surroundings (Stealth+).",
        "Your skin blends seamlessly with your surroundings (Stealth++).",
        "Your skin perfectly mimics your surroundings (Stealth+++).",
    },
    gain = {
        "Your skin functions as natural camouflage.",
        "Your natural camouflage becomes more effective.",
        "Your natural camouflage becomes more effective.",
    },
    lose = {
        "Your skin no longer functions as natural camouflage.",
        "Your natural camouflage becomes less effective.",
        "Your natural camouflage becomes less effective.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
