-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:30
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TOUGH_SKIN",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "tough skin",
    description =
        "Your epidermis has hardened, providing a small amount of protection. Each level\nof" ..
        " this mutation provides +1 AC.",
    have = {
        "You have tough skin. (AC +1)",
        "You have very tough skin. (AC +2)",
        "You have extremely tough skin. (AC +3)",
    },
    gain = {
        "Your skin toughens.",
        "Your skin toughens.",
        "Your skin toughens.",
    },
    lose = {
        "Your skin feels delicate.",
        "Your skin feels delicate.",
        "Your skin feels delicate.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
