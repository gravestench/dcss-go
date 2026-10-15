-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:346
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SLOW",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = true,
    short_description = "slowness",
    description =
        "You cover ground slowly - moving to new positions takes you more time. This\nhas no" ..
        " effect on other types of actions, like attacking or casting spells.\nEach level of" ..
        " this mutation makes you move slower.",
    have = {
        "You cover ground slowly.",
        "You cover ground very slowly.",
        "You cover ground extremely slowly.",
    },
    gain = {
        "You feel sluggish.",
        "You feel sluggish.",
        "You feel sluggish.",
    },
    lose = {
        "You feel quick.",
        "You feel quick.",
        "You feel quick.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
