-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1903
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_LOVE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "hated by all",
    description =
        "You are hated by all and cannot acquire allies, temporarily or permanently, by\nany" ..
        " means. Simplistic, unthinking magical constructs, such as spectral weapons,\norbs of" ..
        " destruction, and battlespheres, are unaffected.",
    have = {
        "You are hated by all.",
        "",
        "",
    },
    gain = {
        "You are now hated by all.",
        "",
        "",
    },
    lose = {
        "You are no longer hated by all.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
