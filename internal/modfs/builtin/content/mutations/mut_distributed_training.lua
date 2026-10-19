-- mut distributed training (MUT_DISTRIBUTED_TRAINING) has up to 1 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DISTRIBUTED_TRAINING",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "distributed training",
    description =
        "Whenever you gain experience, it is split between all of your skills. You\ncannot" ..
        " choose to focus. Effects that prevent you from training certain skills,\nsuch as" ..
        " divine restrictions, do not cause your other skills to rise faster.",
    -- These mut distributed training descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "Your experience applies equally to all skills.",
        "",
        "",
    },
    gain = {
        "Your experience now applies equally to all skills.",
        "",
        "",
    },
    lose = {
        "Your experience no longer applies equally to all skills.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
