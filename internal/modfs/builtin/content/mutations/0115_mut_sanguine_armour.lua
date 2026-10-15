-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1589
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SANGUINE_ARMOUR",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "sanguine armour",
    description =
        "When seriously injured, your blood congeals around you, forming armour. Each\nlevel of" ..
        " this mutation increases the AC provided.",
    have = {
        "When seriously injured, your blood forms armour. (AC +",
        "When seriously injured, your blood forms thick armour. (AC +",
        "When seriously injured, your blood forms very thick armour. (AC +",
    },
    gain = {
        "You feel your blood ready itself to protect you.",
        "You feel your blood thicken.",
        "You feel your blood thicken.",
    },
    lose = {
        "You feel your blood become entirely quiescent.",
        "You feel your blood thin.",
        "You feel your blood thin.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
