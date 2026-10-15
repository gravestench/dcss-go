-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2280
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_INNATE_CASTER",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "innate caster",
    description =
        "You cannot learn spells from books. Instead, as you gain experience, spells\nof higher" ..
        " and higher level bubble up from your fiery heart. These spells are\nunpredictable and" ..
        " unaffected by your choice of god. You cannot train specific\nspell schools - the" ..
        " Spellcasting skill alone determines these spells' success\nrate and power.",
    have = {
        "You learn spells naturally, not from books.",
        "",
        "",
    },
    gain = {
        "You feel mystic power welling inside you.",
        "",
        "",
    },
    lose = {
        "You feel a greater respect for book-learning.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
