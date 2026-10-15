-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:279
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CLUMSY",
    status = "active",
    weight = 8,
    max_level = 2,
    uses = {
        "bad",
        "xom",
    },
    form_based = false,
    short_description = "clumsy",
    description =
        "Your reflexes have become unnaturally clumsy. Each level of this mutation\nprovides -2" ..
        " Dexterity.",
    have = {
        "You are clumsy. (Dex -2)",
        "You are very clumsy. (Dex -4)",
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
