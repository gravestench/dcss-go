-- mut innate caster (MUT_INNATE_CASTER) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
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
    -- These mut innate caster descriptions are indexed by the player's effective
    -- mutation level.
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
