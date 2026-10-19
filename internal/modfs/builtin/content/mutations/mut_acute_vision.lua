-- mut acute vision (MUT_ACUTE_VISION) has up to 1 levels and selection weight
-- 2.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ACUTE_VISION",
    status = "active",
    weight = 2,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "see invisible",
    description =
        "You have supernaturally acute eyesight, allowing you to see monsters that are\nhidden" ..
        " from mundane sight. This has no effect on your accuracy otherwise.",
    -- These mut acute vision descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have supernaturally acute eyesight. (SInv)",
        "",
        "",
    },
    gain = {
        "Your vision sharpens.",
        "",
        "",
    },
    lose = {
        "Your vision seems duller.",
        "",
        "",
    },
    tile_id = "TILEG_MUT_ACUTE_VISION",
}

register.definition(categories.MUTATIONS, definition)

return definition
