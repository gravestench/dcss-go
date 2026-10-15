-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:330
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FAST",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "speed",
    description =
        "You cover ground quickly - moving to new positions takes you less time. This\nhas no" ..
        " effect on other types of actions, like attacking or casting spells.\nEach level of" ..
        " this mutation makes you move faster.",
    have = {
        "You cover ground quickly. (Speed+)",
        "You cover ground very quickly. (Speed++)",
        "You cover ground extremely quickly. (Speed+++)",
    },
    gain = {
        "You feel quick.",
        "You feel quick.",
        "You feel quick.",
    },
    lose = {
        "You feel sluggish.",
        "You feel sluggish.",
        "You feel sluggish.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
