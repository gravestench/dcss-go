-- mut icy blue scales (MUT_ICY_BLUE_SCALES) has up to 3 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ICY_BLUE_SCALES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "icy blue scales",
    description =
        "You are covered in blue scales, providing a small amount of protection. Each\nlevel of" ..
        " this mutation provides more AC. The third level of this mutation also\nprovides" ..
        " resistance to cold.",
    -- These mut icy blue scales descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are partially covered in icy blue scales. (AC +2)",
        "You are mostly covered in icy blue scales. (AC +3)",
        "You are completely covered in icy blue scales. (AC +4, rC+)",
    },
    gain = {
        "Icy blue scales grow over part of your body.",
        "Icy blue scales spread over more of your body.",
        "Icy blue scales cover your body completely.",
    },
    lose = {
        "Your icy blue scales disappear.",
        "Your icy blue scales recede somewhat.",
        "Your icy blue scales recede somewhat.",
    },
    tile_id = "TILEG_MUT_ICY_BLUE_SCALES",
}

register.definition(categories.MUTATIONS, definition)

return definition
