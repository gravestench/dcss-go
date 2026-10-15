-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1573
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_STURDY_FRAME",
    status = "active",
    weight = 2,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "sturdy frame",
    description =
        "Your movements are less encumbered by armour, mitigating penalties to spell\nsuccess" ..
        " and accuracy. Each level of this mutation reduces armour ER by 2.",
    have = {
        "Your movements are slightly less encumbered by armour. (ER -2)",
        "Your movements are less encumbered by armour. (ER -4)",
        "Your movements are significantly less encumbered by armour. (ER -6)",
    },
    gain = {
        "You feel less encumbered by your armour.",
        "You feel less encumbered by your armour.",
        "You feel less encumbered by your armour.",
    },
    lose = {
        "You feel more encumbered by your armour.",
        "You feel more encumbered by your armour.",
        "You feel more encumbered by your armour.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
