-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

register.job{
    id = "JOB_WARPER",
    source_path = "crawl-ref/source/job-data.h",
    abbreviation = "Wr",
    name = "Warper",
    strength = 3,
    intelligence = 5,
    dexterity = 4,
    recommended_species = {
        "SP_FELID",
        "SP_METEORAN",
        "SP_SPRIGGAN",
        "SP_PALENTONGA",
        "SP_BASE_DRACONIAN",
    },
    spells = {
        "SPELL_BLINK",
        "SPELL_BECKONING",
        "SPELL_GRAVITAS",
        "SPELL_TELEPORT_OTHER",
        "SPELL_MANIFOLD_ASSAULT",
    },
    equipment = {
        "leather armour",
        "scroll of blinking",
        "boomerang ego:dispersal q:7",
    },
    weapon_choice = "WCHOICE_PLAIN",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 2,
        },
        {
            id = "SK_ARMOUR",
            level = 1,
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
            id = "SK_TRANSLOCATIONS",
            level = 3,
        },
        {
            id = "SK_THROWING",
            level = 1,
        },
        {
            id = "SK_WEAPON",
            level = 2,
        },
    },
    selectable = true,
}
