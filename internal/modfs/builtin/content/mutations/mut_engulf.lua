-- mut engulf (MUT_ENGULF) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ENGULF",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "engulf",
    description =
        "Your melee attacks may engulf living foes that are your size or smaller.\nThose foes" ..
        " will be silenced and unable to breathe.",
    -- These mut engulf descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "Your melee attacks may engulf your foes in ooze.",
        "",
        "",
    },
    gain = {
        "You begin exuding ooze.",
        "",
        "",
    },
    lose = {
        "You stop exuding ooze.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
