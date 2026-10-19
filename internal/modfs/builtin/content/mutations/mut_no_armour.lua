-- mut no armour (MUT_NO_ARMOUR) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_ARMOUR",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no armour",
    description = "You cannot wear armour.",
    -- These mut no armour descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You cannot wear armour.",
        "",
        "",
    },
    gain = {
        "You can no longer wear armour.",
        "",
        "",
    },
    lose = {
        "You can now wear armour.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
