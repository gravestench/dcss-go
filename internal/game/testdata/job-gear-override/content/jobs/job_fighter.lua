-- Test mod: replace one job definition and its fixed starting gear.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")

local definition = {
    id = "JOB_FIGHTER",
    abbreviation = "Fi",
    name = "Fighter",
    strength = 8,
    intelligence = 0,
    dexterity = 4,
    recommended_species = {
        "SP_METEORAN",
        "SP_HILL_ORC",
        "SP_TROLL",
        "SP_MINOTAUR",
        "SP_GARGOYLE",
        "SP_PALENTONGA",
    },
    spells = mod.null,
    equipment = {
        "scale mail",
        "buckler",
        "potion of curing",
    },
    weapon_choice = "WCHOICE_GOOD",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 3,
        },
        {
            id = "SK_SHIELDS",
            level = 3,
        },
        {
            id = "SK_ARMOUR",
            level = 3,
        },
        {
            id = "SK_WEAPON",
            level = 2,
        },
    },
    selectable = true,
    starting_grants = {
        {
            kind_id = "ARM_SCALE_MAIL",
            quantity = 1,
        },
        {
            kind_id = "ARM_BUCKLER",
            quantity = 1,
        },
        {
            kind_id = "POT_CURING",
            quantity = 1,
        },
    },
}

register.definition(categories.JOBS, definition)

return definition
