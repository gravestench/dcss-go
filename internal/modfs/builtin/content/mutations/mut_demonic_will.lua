-- mut demonic will (MUT_DEMONIC_WILL) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DEMONIC_WILL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "demonic willpower",
    description =
        "Your willpower has a will of its own, sometimes injuring those who attempt to\nhex" ..
        " you. This mutation also bolsters your Willpower.",
    -- These mut demonic will descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You punish those that try to bend your will. (Will+)",
        "",
        "",
    },
    gain = {
        "You feel wilful.",
        "",
        "",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
