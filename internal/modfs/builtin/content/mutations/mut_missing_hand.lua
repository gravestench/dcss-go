-- mut missing hand (MUT_MISSING_HAND) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MISSING_HAND",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "missing a hand",
    description =
        "You are considerably less handy than you used to be. You cannot wield\ntwo-handed" ..
        " weapons, wear a shield, launch off-handed attacks, or use more than\none magical ring" ..
        " at a time.",
    -- These mut missing hand descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are missing a hand.",
        "",
        "",
    },
    gain = {
        "One of your hands has vanished, leaving only a stump!",
        "",
        "",
    },
    lose = {
        "Your stump has regrown into a hand!",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
