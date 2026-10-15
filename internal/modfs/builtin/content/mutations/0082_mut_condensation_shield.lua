-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1117
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CONDENSATION_SHIELD",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "condensation shield",
    description =
        "A shield of frost guards you, blocking some incoming attacks. Fiery attacks can" ..
        "\ntemporarily melt the shield.",
    have = {
        "A meltable shield of frost defends you. (SH +",
        "",
        "",
    },
    gain = {
        "Frost condenses into a shield before you.",
        "",
        "",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
