-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

register.job{
    id = "JOB_ARTIFICER",
    source_path = "crawl-ref/source/job-data.h",
    abbreviation = "Ar",
    name = "Artificer",
    strength = 4,
    intelligence = 3,
    dexterity = 5,
    recommended_species = {
        "SP_METEORAN",
        "SP_KOBOLD",
        "SP_SPRIGGAN",
        "SP_BASE_DRACONIAN",
        "SP_DEMONSPAWN",
    },
    spells = mod.null,
    equipment = {
        "club",
        "leather armour",
        "wand of flame charges:15",
        "wand of charming charges:15 no_exclude",
        "wand of iceblast charges:5 no_exclude",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_EVOCATIONS",
            level = 3,
        },
        {
            id = "SK_DODGING",
            level = 1,
        },
        {
            id = "SK_FIGHTING",
            level = 1,
        },
        {
            id = "SK_ARMOUR",
            level = 1,
        },
        {
            id = "SK_STEALTH",
            level = 1,
        },
    },
    selectable = true,
}
