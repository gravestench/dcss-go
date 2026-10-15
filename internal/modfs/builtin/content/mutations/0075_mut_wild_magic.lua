-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1025
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_WILD_MAGIC",
    status = "active",
    weight = 6,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "wild magic",
    description =
        "Your spells are slightly harder to cast (increased miscast chance and severity),\nbut" ..
        " more powerful. Each level of this mutation increases both effects further.",
    have = {
        "Your spells are a little harder to cast, but a little more powerful.",
        "Your spells are harder to cast, but more powerful.",
        "Your spells are much harder to cast, but much more powerful.",
    },
    gain = {
        "You feel less in control of your magic.",
        "You feel less in control of your magic.",
        "You feel your magical power running wild!",
    },
    lose = {
        "You regain control of your magic.",
        "You feel more in control of your magic.",
        "You feel more in control of your magic.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
