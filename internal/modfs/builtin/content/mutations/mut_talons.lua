-- mut talons (MUT_TALONS) has up to 3 levels and selection weight 5.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
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
    -- These mut talons descriptions are indexed by the player's effective mutation
    -- level.
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
