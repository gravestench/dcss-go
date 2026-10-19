-- mut slimy green scales (MUT_SLIMY_GREEN_SCALES) has up to 3 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SLIMY_GREEN_SCALES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "slimy green scales",
    description =
        "You are covered in green scales, providing a small amount of protection. Each\nlevel" ..
        " of this mutation provides more AC. The third level of this mutation also\nprovides" ..
        " resistance to poison.",
    -- These mut slimy green scales descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are partially covered in slimy green scales. (AC +2)",
        "You are mostly covered in slimy green scales. (AC +3)",
        "You are completely covered in slimy green scales. (AC +4, rPois)",
    },
    gain = {
        "Slimy green scales grow over part of your body.",
        "Slimy green scales spread over more of your body.",
        "Slimy green scales cover your body completely.",
    },
    lose = {
        "Your slimy green scales disappear.",
        "Your slimy green scales recede somewhat.",
        "Your slimy green scales recede somewhat.",
    },
    tile_id = "TILEG_MUT_SLIMY_GREEN_SCALES",
}

register.definition(categories.MUTATIONS, definition)

return definition
