-- These castable spell IDs exist outside the fixed book catalog for gifts and devices.

-- Player-use IDs outside extant books in pinned DCSS.
-- Source: crawl-ref/source/spl-book.cc:_wand_spells and
-- _player_nonbook_spells at e60ba3568b0c26447ad36ec5c7b963eb04b2778f.
-- The book set is committed separately from crawl-ref/source/book-data.h.
local books = require("data.player_book_spells")

local invoked = {
    SPELL_THROW_FLAME = true,
    SPELL_PARALYSE = true,
    SPELL_DIG = true,
    SPELL_ICEBLAST = true,
    SPELL_POLYMORPH = true,
    SPELL_CHARMING = true,
    SPELL_CORROSIVE_BOLT = true,
    SPELL_BOLT_OF_LIGHT = true,
    SPELL_QUICKSILVER_BOLT = true,
    SPELL_MINDBURST = true,
    SPELL_FASTROOT = true,
    SPELL_THUNDERBOLT = true,
    SPELL_PHANTOM_MIRROR = true,
    SPELL_SONIC_WAVE = true,
    SPELL_SMITING = true,
    SPELL_HURL_DAMNATION = true,
}

local catalog = {
    books = books,
    invoked = invoked,
}

return catalog
