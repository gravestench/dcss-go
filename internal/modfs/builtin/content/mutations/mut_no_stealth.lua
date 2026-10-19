-- mut no stealth (MUT_NO_STEALTH) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_STEALTH",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no stealth",
    description =
        "Your have no Stealth. You will always alert monsters when they see you, and\nthey will" ..
        " track you very effectively.",
    -- These mut no stealth descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You cannot be stealthy.",
        "",
        "",
    },
    gain = {
        "You can no longer be stealthy.",
        "",
        "",
    },
    lose = {
        "You can once more be stealthy.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
