-- mut no poison magic (MUT_NO_POISON_MAGIC) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_POISON_MAGIC",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no poison magic",
    description = "Your Poison Magic skill is 0 and you cannot train the skill.",
    -- These mut no poison magic descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You cannot study or cast Poison magic.",
        "",
        "",
    },
    gain = {
        "You can no longer study or cast Poison magic.",
        "",
        "",
    },
    lose = {
        "You can once more study and cast Poison magic.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
