-- mut yellow scales (MUT_YELLOW_SCALES) has up to 3 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_YELLOW_SCALES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "yellow scales",
    description =
        "You are covered in yellow scales, providing a small amount of protection. Each\nlevel" ..
        " of this mutation provides more AC. The third level of this mutation also\nprovides" ..
        " resistance to acid and corrosion.",
    -- These mut yellow scales descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are partially covered in yellow scales. (AC +2)",
        "You are mostly covered in yellow scales. (AC +3)",
        "You are completely covered in yellow scales. (AC +4, rCorr)",
    },
    gain = {
        "Yellow scales grow over part of your body.",
        "Yellow scales spread over more of your body.",
        "Yellow scales cover your body completely.",
    },
    lose = {
        "Your yellow scales disappear.",
        "Your yellow scales recede somewhat.",
        "Your yellow scales recede somewhat.",
    },
    tile_id = "TILEG_MUT_YELLOW_SCALES",
}

register.definition(categories.MUTATIONS, definition)

return definition
