-- mut nightstalker (MUT_NIGHTSTALKER) has up to 3 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NIGHTSTALKER",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "nightstalker",
    description =
        "You are attuned to the shadows, reducing the distance that you can see or be\nseen" ..
        " from.",
    -- These mut nightstalker descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are slightly more attuned to the shadows.",
        "You are significantly more attuned to the shadows.",
        "You are completely attuned to the shadows.",
    },
    gain = {
        "You slip into the darkness of the dungeon.",
        "You slip further into the darkness.",
        "You are surrounded by darkness.",
    },
    lose = {
        "Your affinity for the darkness vanishes.",
        "Your affinity for the darkness weakens.",
        "Your affinity for the darkness weakens.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
