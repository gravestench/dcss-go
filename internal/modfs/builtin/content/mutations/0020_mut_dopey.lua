-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:270
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DOPEY",
    status = "active",
    weight = 8,
    max_level = 2,
    uses = {
        "bad",
        "xom",
    },
    form_based = false,
    short_description = "dopey",
    description =
        "Your mind has become unnaturally dopey. Each level of this mutation provides -2" ..
        "\nIntelligence.",
    have = {
        "You are dopey. (Int -2)",
        "You are very dopey. (Int -4)",
        "",
    },
    gain = {
        "",
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
