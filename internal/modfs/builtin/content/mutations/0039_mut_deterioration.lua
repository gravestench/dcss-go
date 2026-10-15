-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:525
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DETERIORATION",
    status = "active",
    weight = 10,
    max_level = 2,
    uses = {
        "bad",
        "xom",
    },
    form_based = false,
    short_description = "deterioration",
    description =
        "When injured, your body sometimes deteriorates, temporarily reducing your\nattributes." ..
        " The second level of this mutation makes this happen more often.",
    have = {
        "Your body sometimes deteriorates upon taking damage.",
        "Your body often deteriorates upon taking damage.",
        "",
    },
    gain = {
        "You feel yourself wasting away.",
        "You feel your body start to fall apart.",
        "",
    },
    lose = {
        "You feel healthier.",
        "You feel a little healthier.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
