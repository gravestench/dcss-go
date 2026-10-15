-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:73
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_POISON_RESISTANCE",
    status = "active",
    weight = 4,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "poison resistance",
    description =
        "You resist poisons, toxins and other contaminants. This does not confer\nfull" ..
        " immunity, but reduces your chances of being affected to roughly\none-third what it" ..
        " would be otherwise.",
    have = {
        "Your system is resistant to poisons. (rPois)",
        "",
        "",
    },
    gain = {
        "You feel resistant to poisons.",
        "",
        "",
    },
    lose = {
        "You feel less resistant to poisons.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
