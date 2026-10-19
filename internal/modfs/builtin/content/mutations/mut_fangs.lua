-- mut fangs (MUT_FANGS) has up to 3 levels and selection weight 1.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FANGS",
    status = "active",
    weight = 1,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "fangs",
    description =
        "You have sharp teeth, allowing you to bite foes when launching melee attacks.\nEach" ..
        " level of this mutation makes your teeth sharper, longer, and stronger.",
    -- These mut fangs descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You have very sharp teeth.",
        "You have extremely sharp teeth.",
        "You have razor-sharp teeth.",
    },
    gain = {
        "Your teeth lengthen and sharpen.",
        "Your teeth lengthen and sharpen some more.",
        "Your teeth grow very long and razor-sharp.",
    },
    lose = {
        "Your teeth shrink to normal size.",
        "Your teeth shrink and become duller.",
        "Your teeth shrink and become duller.",
    },
    tile_id = "TILEG_MUT_FANGS",
}

register.definition(categories.MUTATIONS, definition)

return definition
