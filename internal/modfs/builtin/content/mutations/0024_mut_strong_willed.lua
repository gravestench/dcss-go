-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:314
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STRONG_WILLED",
    status = "active",
    weight = 5,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "strong-willed",
    description =
        "You have an unnaturally strong will, improving your resistance to certain types\nof" ..
        " hostile magic. Each level of this mutation increases your willpower further.",
    have = {
        "You are strong-willed. (Will+)",
        "You are highly strong-willed. (Will++)",
        "You are extremely strong-willed. (Will+++)",
    },
    gain = {
        "You feel strong-willed.",
        "You feel more strong-willed.",
        "You feel your will become almost unbreakable.",
    },
    lose = {
        "You no longer feel strong-willed.",
        "You feel less strong-willed.",
        "You feel less strong-willed.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
