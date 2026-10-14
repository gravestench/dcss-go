-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

register.job{
    id = "JOB_EARTH_ELEMENTALIST",
    source_path = "crawl-ref/source/job-data.h",
    abbreviation = "EE",
    name = "Earth Elementalist",
    strength = 0,
    intelligence = 7,
    dexterity = 5,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_SPRIGGAN",
        "SP_GARGOYLE",
        "SP_DEMIGOD",
        "SP_GHOUL",
        "SP_OCTOPODE",
    },
    spells = {
        "SPELL_SANDBLAST",
        "SPELL_PASSWALL",
        "SPELL_STONE_ARROW",
        "SPELL_PETRIFY",
    },
    equipment = {
        "robe",
        "potion of magic",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_TRANSMUTATIONS",
            level = 1,
        },
        {
            id = "SK_EARTH_MAGIC",
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
