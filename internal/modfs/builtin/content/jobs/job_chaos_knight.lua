-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

register.job{
    id = "JOB_CHAOS_KNIGHT",
    source_path = "crawl-ref/source/job-data.h",
    abbreviation = "CK",
    name = "Chaos Knight",
    strength = 4,
    intelligence = 4,
    dexterity = 4,
    recommended_species = {
        "SP_HILL_ORC",
        "SP_TROLL",
        "SP_GNOLL",
        "SP_MERFOLK",
        "SP_MINOTAUR",
        "SP_BASE_DRACONIAN",
        "SP_DEMONSPAWN",
    },
    spells = mod.null,
    equipment = {
        "leather armour plus:2",
        "piece from Xom's chessboard",
    },
    weapon_choice = "WCHOICE_PLAIN",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 3,
        },
        {
            id = "SK_ARMOUR",
            level = 1,
        },
        {
            id = "SK_DODGING",
            level = 1,
        },
        {
            id = "SK_WEAPON",
            level = 3,
        },
    },
    selectable = true,
}
