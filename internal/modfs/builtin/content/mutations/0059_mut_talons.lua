-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:818
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TALONS",
    status = "active",
    weight = 5,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "talons",
    description =
        "You have sharp toenails, allowing you to kick foes when launching melee attacks\nif" ..
        " you aren't wearing boots. Each level of this mutation makes your nails\nsharper," ..
        " longer, and stronger. The third level of this mutation prevents you\nfrom wearing" ..
        " boots.",
    have = {
        "You have sharp toenails.",
        "You have razor-sharp toenails.",
        "You have claws for feet.",
    },
    gain = {
        "Your toenails lengthen and sharpen.",
        "Your toenails lengthen and sharpen.",
        "Your feet stretch into talons.",
    },
    lose = {
        "Your talons dull and shrink into feet.",
        "Your talons look more like feet.",
        "Your talons look more like feet.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
