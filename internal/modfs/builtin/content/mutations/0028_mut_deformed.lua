-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:372
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DEFORMED",
    status = "active",
    weight = 8,
    max_level = 1,
    uses = {
        "bad",
        "xom",
    },
    form_based = true,
    short_description = "deformed body",
    description =
        "Your body is shaped in an inhuman way, somewhat reducing the amount of\nprotection" ..
        " provided by body armour. This has no effect on protection provided\nby armour" ..
        " enchantments, nor on the defensive benefits of training the Armour\nskill.",
    have = {
        "Armour fits poorly on your strangely shaped body.",
        "",
        "",
    },
    gain = {
        "Your body twists and deforms.",
        "",
        "",
    },
    lose = {
        "Your body's shape seems more normal.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
