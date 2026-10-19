-- mut inhibited regeneration (MUT_INHIBITED_REGENERATION) has up to 1 levels
-- and selection weight 3.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_INHIBITED_REGENERATION",
    status = "active",
    weight = 3,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "inhibited regeneration",
    description =
        "You do not heal over time while foes are in sight. Other sources of healing,\nsuch as" ..
        " potions, are unaffected.",
    -- These mut inhibited regeneration descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You do not regenerate when monsters are visible.",
        "",
        "",
    },
    gain = {
        "Your regeneration stops near monsters.",
        "",
        "",
    },
    lose = {
        "You begin to regenerate regardless of the presence of monsters.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
