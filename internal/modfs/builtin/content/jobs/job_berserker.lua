-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

register.job{
    id = "JOB_BERSERKER",
    source_path = "crawl-ref/source/job-data.h",
    abbreviation = "Be",
    name = "Berserker",
    strength = 9,
    intelligence = -1,
    dexterity = 4,
    recommended_species = {
        "SP_HILL_ORC",
        "SP_OGRE",
        "SP_MERFOLK",
        "SP_MINOTAUR",
        "SP_GARGOYLE",
        "SP_PALENTONGA",
    },
    spells = mod.null,
    equipment = {
        "animal skin",
    },
    weapon_choice = "WCHOICE_PLAIN",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 3,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_WEAPON",
            level = 3,
        },
    },
    selectable = true,
}
