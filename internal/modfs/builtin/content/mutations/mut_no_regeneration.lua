-- mut no regeneration (MUT_NO_REGENERATION) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_REGENERATION",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no regeneration",
    description =
        "You do not regenerate health while resting, and are unable to receive the\neffects of" ..
        " magic that hastens the speed of regeneration. Sources of HP gain\nsuch as potions and" ..
        " religious invocations will still heal you, and certain\ndivine invocations can" ..
        " temporarily grant you the ability to regenerate.\nTo compensate, you are able to heal" ..
        " yourself via the\n<input>$cmd[CMD_USE_ABILITY]</input> key, at the cost of permanent" ..
        " MP.",
    -- These mut no regeneration descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You do not regenerate.",
        "",
        "",
    },
    gain = {
        "You stop regenerating.",
        "",
        "",
    },
    lose = {
        "You start regenerating.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
