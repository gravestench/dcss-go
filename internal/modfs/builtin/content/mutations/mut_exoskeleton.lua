-- mut exoskeleton (MUT_EXOSKELETON) has up to 2 levels and selection weight
-- 0.
-- This removed source mutation keeps its ID and historical text.
-- The record does not grant an active mutation effect.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MUT_EXOSKELETON",
    status = "removed",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "exoskeleton",
    -- These mut exoskeleton descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your body is surrounded by an exoskeleton. (buggy)",
        "Your body is surrounded by a tough exoskeleton. (buggy)",
        "",
    },
    gain = {
        "Your exoskeleton hardens.",
        "Your exoskeleton becomes even harder.",
        "",
    },
    lose = {
        "Your exoskeleton softens.",
        "Your exoskeleton softens.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
