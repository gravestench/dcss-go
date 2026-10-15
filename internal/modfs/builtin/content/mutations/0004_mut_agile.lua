-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:64
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_AGILE",
    status = "active",
    weight = 7,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "agile",
    description =
        "Your reflexes have become unnaturally fast. Each level of this mutation\nprovides +4" ..
        " Dexterity, but the rest of your body can't keep up with your speed,\ngiving -1 to" ..
        " both your Strength and Intelligence for each level.",
    have = {
        "You are agile. (Dex +4, Str/Int -1)",
        "You are very agile. (Dex +8, Str/Int -2)",
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
