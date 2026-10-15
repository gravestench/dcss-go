-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1252
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_GELATINOUS_BODY",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "gelatinous body",
    description =
        "Your body is rubbery, and your foes like glue. Each level of this mutation\nconfers +1" ..
        " AC and +1 EV.",
    have = {
        "Your rubbery body absorbs attacks. (AC +1, EV +1)",
        "Your pliable body absorbs attacks. (AC +2, EV +2)",
        "Your gelatinous body deflects attacks. (AC +3, EV +3)",
    },
    gain = {
        "Your body becomes stretchy.",
        "Your body becomes more malleable.",
        "Your body becomes viscous.",
    },
    lose = {
        "Your body returns to its normal consistency.",
        "Your body becomes less malleable.",
        "Your body becomes less viscous.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
