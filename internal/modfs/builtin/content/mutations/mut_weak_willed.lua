-- mut weak willed (MUT_WEAK_WILLED) has up to 3 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_WEAK_WILLED",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "weak-willed",
    description =
        "You have an unnaturally weak will, reducing your resistance to certain types\nof" ..
        " hostile magic. Each level of this mutation reduces your willpower further.",
    -- These mut weak willed descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are slightly weak-willed. (Will-)",
        "You are weak-willed. (Will--)",
        "You are extremely weak-willed. (Will---)",
    },
    gain = {
        "You feel weak-willed.",
        "You feel more weak-willed.",
        "You feel more weak-willed.",
    },
    lose = {
        "You no longer feel weak-willed.",
        "You feel less weak-willed.",
        "You feel less weak-willed.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
