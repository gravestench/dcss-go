-- mut tough skin (MUT_TOUGH_SKIN) has up to 3 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TOUGH_SKIN",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "tough skin",
    description =
        "Your epidermis has hardened, providing a small amount of protection. Each level\nof" ..
        " this mutation provides +1 AC.",
    -- These mut tough skin descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have tough skin. (AC +1)",
        "You have very tough skin. (AC +2)",
        "You have extremely tough skin. (AC +3)",
    },
    gain = {
        "Your skin toughens.",
        "Your skin toughens.",
        "Your skin toughens.",
    },
    lose = {
        "Your skin feels delicate.",
        "Your skin feels delicate.",
        "Your skin feels delicate.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
