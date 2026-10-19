-- mut teleport (MUT_TELEPORT) has up to 2 levels and selection weight 3.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TELEPORT",
    status = "active",
    weight = 3,
    max_level = 2,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "teleportitis",
    description =
        "You occasionally teleport across the level to hostile monsters. Each level of\nthis" ..
        " mutation increases the frequency with which this occurs.",
    -- These mut teleport descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are occasionally teleported next to monsters.",
        "You are often teleported next to monsters.",
        "",
    },
    gain = {
        "You feel weirdly uncertain.",
        "You feel even more weirdly uncertain.",
        "",
    },
    lose = {
        "You feel stable.",
        "You feel stable.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
