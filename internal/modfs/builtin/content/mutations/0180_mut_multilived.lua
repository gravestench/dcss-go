-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2221
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MULTILIVED",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "multi-lived",
    description =
        "Every third experience level, you gain an extra life. If you are slain while\nyou" ..
        " still have a life remaining, you will reappear on another part of the\ncurrent floor," ..
        " losing an experience level in the process. You can continue to\ngain extra lives even" ..
        " once you reach the maximum experience level, but you\ncan't have more than two extra" ..
        " lives in reserve at any given time.",
    have = {
        "You gain extra lives every three experience levels.",
        "",
        "",
    },
    gain = {
        "You are no longer multi-lived.",
        "",
        "",
    },
    lose = {
        "You can now gain extra lives.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
