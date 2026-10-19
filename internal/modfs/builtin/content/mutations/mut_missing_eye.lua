-- mut missing eye (MUT_MISSING_EYE) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MISSING_EYE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "missing an eye",
    description =
        "You are missing an eye, reducing the accuracy of your physical and magical\nattacks.",
    -- These mut missing eye descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are missing an eye, making it more difficult to aim.",
        "",
        "",
    },
    gain = {
        "Your right eye vanishes! The world loses its depth.",
        "",
        "",
    },
    lose = {
        "Your right eye suddenly reappears! The world regains its depth.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
