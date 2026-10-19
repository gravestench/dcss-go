-- mut teleport control (MUT_TELEPORT_CONTROL) has up to 1 levels and
-- selection weight 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TELEPORT_CONTROL",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "teleport control",
    -- These mut teleport control descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You can control translocations.",
        "",
        "",
    },
    gain = {
        "You feel controlled.",
        "",
        "",
    },
    lose = {
        "You feel random.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
