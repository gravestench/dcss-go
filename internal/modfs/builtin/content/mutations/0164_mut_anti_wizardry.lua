-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2075
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ANTI_WIZARDRY",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "disrupted magic",
    description =
        "Your chance to miscast spells is higher. Each level of this sacrifice increases\nthe" ..
        " chance to miscast further.",
    have = {
        "Your casting is slightly disrupted.",
        "Your casting is disrupted.",
        "Your casting is seriously disrupted.",
    },
    gain = {
        "Your ability to control magic is disrupted.",
        "Your ability to control magic is more disrupted.",
        "Your ability to control magic is more disrupted.",
    },
    lose = {
        "Your ability to control magic is no longer disrupted.",
        "Your ability to control magic is less disrupted.",
        "Your ability to control magic is less disrupted.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
