-- mut spiny (MUT_SPINY) has up to 3 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SPINY",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "spiny",
    description =
        "Foes who strike you in melee have a 50% chance of being impaled on your spines," ..
        "\ntaking damage. Each level of this mutation increases the damage.",
    -- These mut spiny descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You are partially covered in sharp spines.",
        "You are mostly covered in sharp spines.",
        "You are completely covered in sharp spines.",
    },
    gain = {
        "Sharp spines emerge from parts of your body.",
        "Sharp spines emerge from more of your body.",
        "Sharp spines emerge from your entire body.",
    },
    lose = {
        "Your sharp spines disappear entirely.",
        "Your sharp spines retract somewhat.",
        "Your sharp spines retract somewhat.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
