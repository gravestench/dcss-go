-- mut shaggy fur (MUT_SHAGGY_FUR) has up to 3 levels and selection weight 2.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
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
    -- These mut shaggy fur descriptions are indexed by the player's effective
    -- mutation level.
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
