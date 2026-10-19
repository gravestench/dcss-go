-- mut thin skeletal structure (MUT_THIN_SKELETAL_STRUCTURE) has up to 3
-- levels and selection weight 2.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_THIN_SKELETAL_STRUCTURE",
    status = "active",
    weight = 2,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "thin skeletal structure",
    description =
        "Your bones are light and porous. Each level of this mutation provides +2\nDexterity" ..
        " and Stealth+.",
    -- These mut thin skeletal structure descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You have a somewhat thin skeletal structure. (Dex +2, Stealth+)",
        "You have a moderately thin skeletal structure. (Dex +4, Stealth++)",
        "You have an unnaturally thin skeletal structure. (Dex +6, Stealth+++)",
    },
    gain = {
        "Your bones become slightly less dense.",
        "Your bones become somewhat less dense.",
        "Your bones become less dense.",
    },
    lose = {
        "Your skeletal structure returns to normal.",
        "Your skeletal structure densifies.",
        "Your skeletal structure densifies.",
    },
    tile_id = "TILEG_MUT_THIN_SKELETAL_STRUCTURE",
}

register.definition(categories.MUTATIONS, definition)

return definition
