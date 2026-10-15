-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:653
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TORMENT_RESISTANCE",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "torment resistance",
    description =
        "You are less affected by unholy torment, which would otherwise cut your health\nin" ..
        " half. The second level of this mutation renders you entirely immune.",
    have = {
        "You are resistant to unholy torment.",
        "You are immune to unholy pain and torment.",
        "",
    },
    gain = {
        "You feel a strange anaesthesia.",
        "You feel a very strange anaesthesia.",
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
