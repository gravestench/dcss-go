-- mut berserk (MUT_BERSERK) has up to 2 levels and selection weight 7.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BERSERK",
    status = "active",
    weight = 7,
    max_level = 2,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "berserk",
    description =
        "When attacking foes in melee, you sometimes enter a berserk rage. Each level of\nthis" ..
        " mutation makes it easier for you to lose your temper.",
    -- These mut berserk descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You sometimes lose your temper in combat.",
        "You have an uncontrollable temper.",
        "",
    },
    gain = {
        "You feel a little pissed off.",
        "You feel extremely angry at everything!",
        "",
    },
    lose = {
        "You feel a little more calm.",
        "You feel a little less angry.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
