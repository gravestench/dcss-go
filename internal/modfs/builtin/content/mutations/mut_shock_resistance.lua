-- mut shock resistance (MUT_SHOCK_RESISTANCE) has up to 1 levels and
-- selection weight 2.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SHOCK_RESISTANCE",
    status = "active",
    weight = 2,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "electricity resistance",
    description = "You resist electricity (rElec), taking less damage from it.",
    -- These mut shock resistance descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are resistant to electric shocks. (rElec)",
        "",
        "",
    },
    gain = {
        "You feel insulated.",
        "",
        "",
    },
    lose = {
        "You feel conductive.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
