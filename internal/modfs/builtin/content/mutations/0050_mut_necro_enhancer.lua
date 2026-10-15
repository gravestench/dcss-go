-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:693
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NECRO_ENHANCER",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "in touch with death",
    description =
        "Your Necromancy spells are more powerful. The second level of this mutation\nenhances" ..
        " your Necromancy spellpower further.",
    have = {
        "You are in touch with the powers of death.",
        "You are strongly in touch with the powers of death.",
        "",
    },
    gain = {
        "You feel more in touch with the powers of death.",
        "You feel more in touch with the powers of death.",
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
