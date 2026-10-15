-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2329
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DIVINE_ATTRS",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "divine attributes",
    description =
        "Your divine heritage dramatically boosts your attribute gain (Strength,\nIntelligence," ..
        " and Dexterity) as you level up relative to other species, both\nin quantity and in" ..
        " how much you can control your development. Every three\nlevels, you choose an" ..
        " attribute to increase by four points.",
    have = {
        "Your divine heritage dramatically boosts your attributes as you level up.",
        "",
        "",
    },
    gain = {
        "You feel more divine.",
        "",
        "",
    },
    lose = {
        "You feel more mortal.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
