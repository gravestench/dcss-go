-- Spell-slot flags describe when a monster can choose a spell, including emergencies.

-- Source: crawl-ref/source/externs.h, mon_spell_slot_flags.
local flags = {
    BREATH = "MON_SPELL_BREATH",
    EMERGENCY = "MON_SPELL_EMERGENCY",
    INSTANT = "MON_SPELL_INSTANT",
    SHORT_RANGE = "MON_SPELL_SHORT_RANGE",
    LONG_RANGE = "MON_SPELL_LONG_RANGE",
    MAGICAL = "MON_SPELL_MAGICAL",
    NATURAL = "MON_SPELL_NATURAL",
    NO_FLAGS = "MON_SPELL_NO_FLAGS",
    NO_SILENT = "MON_SPELL_NO_SILENT",
    NOISY = "MON_SPELL_NOISY",
    PRIEST = "MON_SPELL_PRIEST",
    VOCAL = "MON_SPELL_VOCAL",
    WIZARD = "MON_SPELL_WIZARD",
    EVOKE = "MON_SPELL_EVOKE",
}

return flags
