-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2229
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
