-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2165
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ACID_RESISTANCE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "acid resistance",
    description =
        "You resist acid (rCorr), taking less damage from it. You are also less likely to" ..
        "\nbecome corroded.",
    have = {
        "You are resistant to acid. (rCorr)",
        "",
        "",
    },
    gain = {
        "You feel resistant to acid.",
        "",
        "",
    },
    lose = {
        "You feel less resistant to acid.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
