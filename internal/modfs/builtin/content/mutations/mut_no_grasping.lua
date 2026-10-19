-- mut no grasping (MUT_NO_GRASPING) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_GRASPING",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no weapons or thrown items",
    description = "You are incapable of wielding weapons or throwing items.",
    -- These mut no grasping descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are incapable of wielding weapons or throwing items.",
        "",
        "",
    },
    gain = {
        "You can no longer grasp objects.",
        "",
        "",
    },
    lose = {
        "You can now grasp objects.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
