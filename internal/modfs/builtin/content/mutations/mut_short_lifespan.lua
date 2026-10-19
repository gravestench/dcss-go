-- mut short lifespan (MUT_SHORT_LIFESPAN) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SHORT_LIFESPAN",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "otherworldly",
    description =
        "You are foreign to this world, easily perceived by dark forces. You have only" ..
        "\none-tenth the normal time on each dungeon floor before Zot finds and ends you.",
    -- These mut short lifespan descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are easily found by Zot.",
        "",
        "",
    },
    gain = {
        "You feel your time running out.",
        "",
        "",
    },
    lose = {
        "You feel long-lived.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
