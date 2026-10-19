-- mut explore regen (MUT_EXPLORE_REGEN) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_EXPLORE_REGEN",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "explore regen",
    description =
        "As you explore the dungeon, your wounds will heal and your magic will replenish.",
    -- These mut explore regen descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You regain HP and MP as you explore.",
        "",
        "",
    },
    gain = {
        "You feel a fierce wanderlust.",
        "",
        "",
    },
    lose = {
        "You feel like a homebody.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
