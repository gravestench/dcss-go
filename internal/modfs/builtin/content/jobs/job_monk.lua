-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

register.job{
    id = "JOB_MONK",
    source_path = "crawl-ref/source/job-data.h",
    abbreviation = "Mo",
    name = "Monk",
    strength = 3,
    intelligence = 2,
    dexterity = 7,
    recommended_species = {
        "SP_METEORAN",
        "SP_HILL_ORC",
        "SP_TROLL",
        "SP_PALENTONGA",
        "SP_MERFOLK",
        "SP_GARGOYLE",
        "SP_DEMONSPAWN",
    },
    spells = mod.null,
    equipment = {
        "robe",
        "potion of ambrosia",
    },
    weapon_choice = "WCHOICE_PLAIN",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 3,
        },
        {
            id = "SK_WEAPON",
            level = 3,
        },
        {
            id = "SK_DODGING",
            level = 3,
        },
        {
            id = "SK_STEALTH",
            level = 2,
        },
    },
    selectable = true,
}
