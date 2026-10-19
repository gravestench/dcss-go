-- mut strong nose (MUT_STRONG_NOSE) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STRONG_NOSE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "strong nose",
    description =
        "You have a powerful nose adapted to the Dungeon's scents, allowing you to\ndetect" ..
        " where treasures lay hidden. As you explore the dungeon, nearby item\nlocations that" ..
        " you cannot directly see will gain a marker for\nas-yet-undiscovered items.",
    -- These mut strong nose descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your uncanny sense of smell can sniff out nearby items.",
        "",
        "",
    },
    gain = {
        "Your sense of smell grows stronger.",
        "",
        "",
    },
    lose = {
        "Your sense of smell gets weaker.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
