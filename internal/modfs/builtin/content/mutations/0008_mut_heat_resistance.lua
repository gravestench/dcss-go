-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:102
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HEAT_RESISTANCE",
    status = "active",
    weight = 4,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "fire resistance",
    description =
        "You resist heat. Each level of this mutation reduces the amount of damage taken\nfrom" ..
        " fire.",
    have = {
        "Your flesh is heat resistant. (rF+)",
        "Your flesh is very heat resistant. (rF++)",
        "Your flesh is almost immune to the effects of heat. (rF+++)",
    },
    gain = {
        "You feel resistant to heat.",
        "You feel more resistant to heat.",
        "You feel more resistant to heat.",
    },
    lose = {
        "You no longer feel heat resistant.",
        "You feel less heat resistant.",
        "You feel less heat resistant.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
