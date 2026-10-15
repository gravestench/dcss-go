-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2149
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
