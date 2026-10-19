-- mut strong willed (MUT_STRONG_WILLED) has up to 3 levels and selection
-- weight 5.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STRONG_WILLED",
    status = "active",
    weight = 5,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "strong-willed",
    description =
        "You have an unnaturally strong will, improving your resistance to certain types\nof" ..
        " hostile magic. Each level of this mutation increases your willpower further.",
    -- These mut strong willed descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are strong-willed. (Will+)",
        "You are highly strong-willed. (Will++)",
        "You are extremely strong-willed. (Will+++)",
    },
    gain = {
        "You feel strong-willed.",
        "You feel more strong-willed.",
        "You feel your will become almost unbreakable.",
    },
    lose = {
        "You no longer feel strong-willed.",
        "You feel less strong-willed.",
        "You feel less strong-willed.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
