-- mut no armour skill (MUT_NO_ARMOUR_SKILL) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_ARMOUR_SKILL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "inability to train armour",
    description = "Your Armour skill is 0 and you cannot train the skill.",
    -- These mut no armour skill descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You cannot train Armour skill.",
        "",
        "",
    },
    gain = {
        "You can no longer train Armour skill.",
        "",
        "",
    },
    lose = {
        "You can once more train Armour skill.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
