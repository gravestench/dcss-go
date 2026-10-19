-- mut no earth magic (MUT_NO_EARTH_MAGIC) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_EARTH_MAGIC",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no earth magic",
    description = "Your Earth Magic skill is 0 and you cannot train the skill.",
    -- These mut no earth magic descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You cannot study or cast Earth magic.",
        "",
        "",
    },
    gain = {
        "You can no longer study or cast Earth magic.",
        "",
        "",
    },
    lose = {
        "You can once more study and cast Earth magic.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
