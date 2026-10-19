-- mut no drink (MUT_NO_DRINK) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_DRINK",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "no potions",
    description = "You are unable to quaff potions.",
    -- These mut no drink descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You do not drink.",
        "",
        "",
    },
    gain = {
        "Your mouth dries to ashes.",
        "",
        "",
    },
    lose = {
        "You gain the ability to drink.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
