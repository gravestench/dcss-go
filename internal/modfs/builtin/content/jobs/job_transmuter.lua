-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

register.job{
    id = "JOB_TRANSMUTER",
    source_path = "crawl-ref/source/job-data.h",
    abbreviation = "Tm",
    name = "Transmuter",
    strength = 2,
    intelligence = 5,
    dexterity = 5,
    recommended_species = {
        "SP_NAGA",
        "SP_MERFOLK",
        "SP_BASE_DRACONIAN",
        "SP_DEMIGOD",
        "SP_DEMONSPAWN",
        "SP_TROLL",
        "SP_METEORAN",
    },
    spells = {
        "SPELL_BEASTLY_APPENDAGE",
        "SPELL_WEREBLOOD",
        "SPELL_SPIDER_FORM",
        "SPELL_ICE_FORM",
    },
    equipment = {
        "robe",
        "potion of lignification",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 1,
        },
        {
            id = "SK_UNARMED_COMBAT",
            level = 3,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_SPELLCASTING",
            level = 2,
        },
        {
            id = "SK_TRANSMUTATIONS",
            level = 2,
        },
    },
    selectable = true,
}
