-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

register.job{
    id = "JOB_GLADIATOR",
    source_path = "crawl-ref/source/job-data.h",
    abbreviation = "Gl",
    name = "Gladiator",
    strength = 6,
    intelligence = 0,
    dexterity = 6,
    recommended_species = {
        "SP_METEORAN",
        "SP_HILL_ORC",
        "SP_MERFOLK",
        "SP_TROLL",
        "SP_GARGOYLE",
        "SP_GNOLL",
    },
    spells = mod.null,
    equipment = {
        "leather armour",
        "helmet",
        "throwing net q:3",
    },
    weapon_choice = "WCHOICE_GOOD",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 2,
        },
        {
            id = "SK_THROWING",
            level = 2,
        },
        {
            id = "SK_DODGING",
            level = 3,
        },
        {
            id = "SK_WEAPON",
            level = 3,
        },
    },
    selectable = true,
}
