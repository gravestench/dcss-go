-- Source player spells available through wands, abilities, and devices
-- outside fixed books. Unlike book membership, these IDs cannot be
-- derived from book definitions and remain an explicit source set.
-- Source: crawl-ref/source/spl-book.cc and _player_nonbook_spells.
local spells = require("ids.spells")

local invoked = {
    [spells.SPELL_THROW_FLAME] = true,
    [spells.SPELL_PARALYSE] = true,
    [spells.SPELL_DIG] = true,
    [spells.SPELL_ICEBLAST] = true,
    [spells.SPELL_POLYMORPH] = true,
    [spells.SPELL_CHARMING] = true,
    [spells.SPELL_CORROSIVE_BOLT] = true,
    [spells.SPELL_BOLT_OF_LIGHT] = true,
    [spells.SPELL_QUICKSILVER_BOLT] = true,
    [spells.SPELL_MINDBURST] = true,
    [spells.SPELL_FASTROOT] = true,
    [spells.SPELL_THUNDERBOLT] = true,
    [spells.SPELL_PHANTOM_MIRROR] = true,
    [spells.SPELL_SONIC_WAVE] = true,
    [spells.SPELL_SMITING] = true,
    [spells.SPELL_HURL_DAMNATION] = true,
}

return invoked
