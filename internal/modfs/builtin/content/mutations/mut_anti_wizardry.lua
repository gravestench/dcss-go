-- mut anti wizardry (MUT_ANTI_WIZARDRY) has up to 3 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ANTI_WIZARDRY",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "disrupted magic",
    description =
        "Your chance to miscast spells is higher. Each level of this sacrifice increases\nthe" ..
        " chance to miscast further.",
    -- These mut anti wizardry descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your casting is slightly disrupted.",
        "Your casting is disrupted.",
        "Your casting is seriously disrupted.",
    },
    gain = {
        "Your ability to control magic is disrupted.",
        "Your ability to control magic is more disrupted.",
        "Your ability to control magic is more disrupted.",
    },
    lose = {
        "Your ability to control magic is no longer disrupted.",
        "Your ability to control magic is less disrupted.",
        "Your ability to control magic is less disrupted.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
