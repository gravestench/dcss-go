-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1501
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
