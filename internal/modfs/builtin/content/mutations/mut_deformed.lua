-- mut deformed (MUT_DEFORMED) has up to 1 levels and selection weight 8.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DEFORMED",
    status = "active",
    weight = 8,
    max_level = 1,
    uses = {
        "bad",
        "xom",
    },
    form_based = true,
    short_description = "deformed body",
    description =
        "Your body is shaped in an inhuman way, somewhat reducing the amount of\nprotection" ..
        " provided by body armour. This has no effect on protection provided\nby armour" ..
        " enchantments, nor on the defensive benefits of training the Armour\nskill.",
    -- These mut deformed descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Armour fits poorly on your strangely shaped body.",
        "",
        "",
    },
    gain = {
        "Your body twists and deforms.",
        "",
        "",
    },
    lose = {
        "Your body's shape seems more normal.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
