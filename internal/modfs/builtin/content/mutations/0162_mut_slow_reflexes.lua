-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2047
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SLOW_REFLEXES",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "reduced EV",
    description = "Your reflexes are slow, making it easier for foes to hit you.",
    have = {
        "You have somewhat slow reflexes. (EV -5)",
        "You have slow reflexes. (EV -10)",
        "You have very slow reflexes. (EV -15)",
    },
    gain = {
        "Your reflexes slow.",
        "Your reflexes slow further.",
        "Your reflexes slow further.",
    },
    lose = {
        "You reflexes return to normal.",
        "You reflexes speed back up.",
        "You reflexes speed back up.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
