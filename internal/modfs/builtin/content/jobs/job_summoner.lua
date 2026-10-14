-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

register.job{
    id = "JOB_SUMMONER",
    source_path = "crawl-ref/source/job-data.h",
    abbreviation = "Su",
    name = "Summoner",
    strength = 0,
    intelligence = 7,
    dexterity = 5,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_HILL_ORC",
        "SP_VINE_STALKER",
        "SP_MERFOLK",
        "SP_TENGU",
        "SP_VAMPIRE",
    },
    spells = {
        "SPELL_SUMMON_SMALL_MAMMAL",
        "SPELL_CALL_IMP",
        "SPELL_CALL_CANINE_FAMILIAR",
        "SPELL_SUMMON_GUARDIAN_GOLEM",
        "SPELL_SUMMON_LIGHTNING_SPIRE",
    },
    equipment = {
        "robe",
        "potion of magic",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_SUMMONINGS",
            level = 4,
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
