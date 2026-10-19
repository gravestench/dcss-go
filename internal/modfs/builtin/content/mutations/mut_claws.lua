-- mut claws (MUT_CLAWS) has up to 3 levels and selection weight 2.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CLAWS",
    status = "active",
    weight = 2,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "claws",
    description =
        "You have sharp nails, increasing the strength of your main-hand unarmed attacks\nif" ..
        " you aren't wearing gloves. If your off-hand is free, the strength of your\noff-hand" ..
        " punch attacks is also increased. Each level of this mutation makes your\nnails" ..
        " sharper, longer, and stronger. The third level of this mutation prevents\nyou from" ..
        " wearing gloves.",
    -- These mut claws descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You have sharp fingernails.",
        "You have very sharp fingernails.",
        "You have claws for hands.",
    },
    gain = {
        "Your fingernails lengthen.",
        "Your fingernails sharpen.",
        "Your hands twist into claws.",
    },
    lose = {
        "Your fingernails shrink to normal size.",
        "Your fingernails look duller.",
        "Your hands feel fleshier.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
