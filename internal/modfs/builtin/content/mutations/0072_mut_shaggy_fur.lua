-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:977
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SHAGGY_FUR",
    status = "active",
    weight = 2,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "shaggy fur",
    description =
        "You are covered in fur, providing a small amount of protection. Each level of\nthis" ..
        " mutation provides +1 AC. The third level of this mutation also provides\nresistance" ..
        " to cold.",
    have = {
        "You are covered in fur. (AC +1)",
        "You are covered in thick fur. (AC +2)",
        "Your thick and shaggy fur keeps you warm. (AC +3, rC+)",
    },
    gain = {
        "Fur sprouts all over your body.",
        "Your fur grows into a thick mane.",
        "Your thick fur grows shaggy and warm.",
    },
    lose = {
        "You shed all your fur.",
        "Your thick fur recedes somewhat.",
        "Your shaggy fur recedes somewhat.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
