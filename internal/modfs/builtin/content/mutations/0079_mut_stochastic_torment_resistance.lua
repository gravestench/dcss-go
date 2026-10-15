-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1080

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STOCHASTIC_TORMENT_RESISTANCE",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "removed torment resistance",
    have = {
        "You are somewhat able to resist unholy torments.",
        "",
        "",
    },
    gain = {
        "You feel a strange anaesthesia.",
        "",
        "",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
