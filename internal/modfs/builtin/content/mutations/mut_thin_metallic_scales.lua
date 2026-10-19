-- mut thin metallic scales (MUT_THIN_METALLIC_SCALES) has up to 3 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_THIN_METALLIC_SCALES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "thin metallic scales",
    description =
        "You are covered in metallic scales, providing a small amount of protection.\nEach" ..
        " level of this mutation provides more AC. The third level of this mutation\nalso" ..
        " provides resistance to electricity.",
    -- These mut thin metallic scales descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are partially covered in thin metallic scales. (AC +2)",
        "You are mostly covered in thin metallic scales. (AC +3)",
        "You are completely covered in thin metallic scales. (AC +4, rElec)",
    },
    gain = {
        "Thin metallic scales grow over part of your body.",
        "Thin metallic scales spread over more of your body.",
        "Thin metallic scales cover your body completely.",
    },
    lose = {
        "Your thin metallic scales disappear.",
        "Your thin metallic scales recede somewhat.",
        "Your thin metallic scales recede somewhat.",
    },
    tile_id = "TILEG_MUT_THIN_METALLIC_SCALES",
}

register.definition(categories.MUTATIONS, definition)

return definition
