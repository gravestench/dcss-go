-- mut tengu flight (MUT_TENGU_FLIGHT) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TENGU_FLIGHT",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "nimble flight",
    description =
        "You fly quickly through the air, covering ground more quickly than you would on\nfoot." ..
        " Your evasion is also multiplied by this effect.",
    -- These mut tengu flight descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your magical nature lets you fly swiftly and evasively.",
        "",
        "",
    },
    gain = {
        "Your magical nature develops, letting you fly swiftly and evasively.",
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
