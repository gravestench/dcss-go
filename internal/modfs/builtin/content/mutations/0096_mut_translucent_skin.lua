-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1284
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TRANSLUCENT_SKIN",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "translucent skin",
    description =
        "Your skin is transparent, improving your stealth and reducing the accuracy of\nyour" ..
        " foes' attacks against you. Each level of this mutation reduces your foes'\naccuracy" ..
        " further.",
    have = {
        "Your translucent skin slightly reduces your foes' accuracy. (Stealth+)",
        "Your translucent skin reduces your foes' accuracy. (Stealth+)",
        "Your transparent skin significantly reduces your foes' accuracy. (Stealth+)",
    },
    gain = {
        "Your skin becomes partially translucent.",
        "Your skin becomes more translucent.",
        "Your skin becomes completely transparent.",
    },
    lose = {
        "Your skin returns to its normal opacity.",
        "Your skin's translucency fades.",
        "Your skin's transparency fades.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
