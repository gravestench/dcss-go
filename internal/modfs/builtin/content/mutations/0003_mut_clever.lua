-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:55
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CLEVER",
    status = "active",
    weight = 7,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "clever",
    description =
        "Your mind has become unnaturally acute. Each level of this mutation provides +4" ..
        "\nIntelligence, but all the blood flowing to your head weakens your constitution," ..
        "\ngiving -1 to both your Strength and Dexterity for each level.",
    have = {
        "Your mind is acute. (Int +4, Str/Dex -1)",
        "Your mind is very acute. (Int +8, Str/Dex -2)",
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
