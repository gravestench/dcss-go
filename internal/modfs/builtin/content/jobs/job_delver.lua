-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

register.job{
    id = "JOB_DELVER",
    source_path = "crawl-ref/source/job-data.h",
    abbreviation = "De",
    name = "Delver",
    strength = 4,
    intelligence = 2,
    dexterity = 6,
    recommended_species = {
        "SP_FELID",
        "SP_SPRIGGAN",
        "SP_KOBOLD",
        "SP_VAMPIRE",
        "SP_GNOLL",
    },
    spells = mod.null,
    equipment = {
        "leather armour",
        "scroll of fog no_exclude",
        "scroll of magic mapping",
        "scroll of fear",
        "potion of haste",
        "wand of digging charges:3",
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
            id = "SK_STEALTH",
            level = 5,
        },
        {
            id = "SK_WEAPON",
            level = 2,
        },
    },
    selectable = true,
}
