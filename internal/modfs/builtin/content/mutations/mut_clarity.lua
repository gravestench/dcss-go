-- mut clarity (MUT_CLARITY) has up to 1 levels and selection weight 6.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CLARITY",
    status = "active",
    weight = 6,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "clarity",
    description =
        "Your mind is exceptionally clear, preventing you from becoming confused,\nmesmerised," ..
        " or supernaturally afraid. You also cannot become involuntarily\nenraged.",
    -- These mut clarity descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You possess an exceptional clarity of mind.",
        "",
        "",
    },
    gain = {
        "Your thoughts seem clearer.",
        "",
        "",
    },
    lose = {
        "Your thinking seems confused.",
        "",
        "",
    },
    tile_id = "TILEG_MUT_CLARITY",
}

register.definition(categories.MUTATIONS, definition)

return definition
