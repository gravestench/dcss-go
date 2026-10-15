-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:742
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BEAK",
    status = "active",
    weight = 1,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "beak",
    description =
        "You have a beak for a mouth, allowing you to peck at foes when launching melee" ..
        "\nattacks, but preventing you from wearing helmets.",
    have = {
        "You have a beak for a mouth.",
        "",
        "",
    },
    gain = {
        "Your mouth lengthens and hardens into a beak!",
        "",
        "",
    },
    lose = {
        "Your beak shortens and softens into a mouth.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
