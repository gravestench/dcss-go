-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2272
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FLOAT",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "float",
    description = "You hover through the air, forever free from the surly bonds of earth.",
    have = {
        "You float through the air rather than walking.",
        "",
        "",
    },
    gain = {
        "You feel both weightless and legless.",
        "",
        "",
    },
    lose = {
        "You feel dragged down by the weight of the world.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
