-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1167
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SPINY",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "spiny",
    description =
        "Foes who strike you in melee have a 50% chance of being impaled on your spines," ..
        "\ntaking damage. Each level of this mutation increases the damage.",
    have = {
        "You are partially covered in sharp spines.",
        "You are mostly covered in sharp spines.",
        "You are completely covered in sharp spines.",
    },
    gain = {
        "Sharp spines emerge from parts of your body.",
        "Sharp spines emerge from more of your body.",
        "Sharp spines emerge from your entire body.",
    },
    lose = {
        "Your sharp spines disappear entirely.",
        "Your sharp spines retract somewhat.",
        "Your sharp spines retract somewhat.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
