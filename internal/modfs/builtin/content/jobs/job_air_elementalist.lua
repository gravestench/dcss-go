-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

register.job{
    id = "JOB_AIR_ELEMENTALIST",
    source_path = "crawl-ref/source/job-data.h",
    abbreviation = "AE",
    name = "Air Elementalist",
    strength = 0,
    intelligence = 7,
    dexterity = 5,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_TENGU",
        "SP_BASE_DRACONIAN",
        "SP_NAGA",
        "SP_VINE_STALKER",
        "SP_DJINNI",
    },
    spells = {
        "SPELL_SHOCK",
        "SPELL_DISCHARGE",
        "SPELL_SWIFTNESS",
        "SPELL_AIRSTRIKE",
    },
    equipment = {
        "robe",
        "potion of magic",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_CONJURATIONS",
            level = 1,
        },
        {
            id = "SK_AIR_MAGIC",
            level = 3,
        },
        {
            id = "SK_SPELLCASTING",
            level = 2,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_STEALTH",
            level = 2,
        },
    },
    selectable = true,
}
