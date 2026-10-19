-- mut sharp scales (MUT_SHARP_SCALES) has up to 3 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SHARP_SCALES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "sharp scales",
    description =
        "You are covered in sharp scales, providing a small amount of protection. Each\nlevel" ..
        " of this mutation provides +1 AC and Slay +1, improving your accuracy and\ndamage with" ..
        " melee and ranged attacks.",
    -- These mut sharp scales descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are partially covered in razor-sharp scales. (AC +1, Slay +1)",
        "You are mostly covered in razor-sharp scales. (AC +2, Slay +2)",
        "You are completely covered in razor-sharp scales. (AC +3, Slay +3)",
    },
    gain = {
        "Sharp scales grow over part of your body.",
        "Sharp scales spread over more of your body.",
        "Sharp scales cover your body completely.",
    },
    lose = {
        "Your sharp scales disappear.",
        "Your sharp scales recede somewhat.",
        "Your sharp scales recede somewhat.",
    },
    tile_id = "TILEG_MUT_SHARP_SCALES",
}

register.definition(categories.MUTATIONS, definition)

return definition
