-- mut iridescent scales (MUT_IRIDESCENT_SCALES) has up to 3 levels and
-- selection weight 10.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_IRIDESCENT_SCALES",
    status = "active",
    weight = 10,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "iridescent scales",
    description =
        "You are covered in iridescent scales, providing a small amount of protection.\nEach" ..
        " level of this mutation provides +2 AC.",
    -- These mut iridescent scales descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are partially covered in iridescent scales. (AC +2)",
        "You are mostly covered in iridescent scales. (AC +4)",
        "You are completely covered in iridescent scales. (AC +6)",
    },
    gain = {
        "Iridescent scales grow over part of your body.",
        "Iridescent scales spread over more of your body.",
        "Iridescent scales cover your body completely.",
    },
    lose = {
        "Your iridescent scales disappear.",
        "Your iridescent scales recede somewhat.",
        "Your iridescent scales recede somewhat.",
    },
    tile_id = "TILEG_MUT_IRIDESCENT_SCALES",
}

register.definition(categories.MUTATIONS, definition)

return definition
