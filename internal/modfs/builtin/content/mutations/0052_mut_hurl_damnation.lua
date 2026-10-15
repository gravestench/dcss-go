-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:715
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HURL_DAMNATION",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "hurl damnation",
    description = "You can hurl damnation with <input>$cmd[CMD_USE_ABILITY]</input>. Foes beware!",
    have = {
        "You can hurl damnation.",
        "",
        "",
    },
    gain = {
        "You smell a hint of brimstone.",
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
