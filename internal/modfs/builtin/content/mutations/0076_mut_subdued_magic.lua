-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1041
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SUBDUED_MAGIC",
    status = "active",
    weight = 6,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "subdued magic",
    description =
        "Your spells are slightly easier to cast (reduced miscast chance and severity),\nbut" ..
        " less powerful. Each level of this mutation increases both effects further.",
    have = {
        "Your spells are a little easier to cast, but a little less powerful.",
        "Your spells are easier to cast, but less powerful.",
        "Your spells are much easier to cast, but much less powerful.",
    },
    gain = {
        "Your connection to magic feels subdued.",
        "Your connection to magic feels more subdued.",
        "Your connection to magic feels nearly dormant.",
    },
    lose = {
        "Your magic regains its normal vibrancy.",
        "Your connection to magic feels less subdued.",
        "Your connection to magic feels less subdued.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
