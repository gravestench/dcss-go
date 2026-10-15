-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")

local definition = {
    id = "JOB_ARCANE_MARKSMAN",
    abbreviation = "AM",
    name = "Arcane Marksman",
    strength = 2,
    intelligence = 5,
    dexterity = 5,
    recommended_species = {
        "SP_FORMICID",
        "SP_DEEP_ELF",
        "SP_KOBOLD",
        "SP_SPRIGGAN",
        "SP_GNOLL",
    },
    spells = {
        "SPELL_SLOW",
        "SPELL_INNER_FLAME",
        "SPELL_PORTAL_PROJECTILE",
        "SPELL_CAUSE_FEAR",
    },
    equipment = {
        "robe",
        "scroll of poison",
        "sling plus:1",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 1,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_SPELLCASTING",
            level = 1,
        },
        {
            id = "SK_HEXES",
            level = 3,
        },
        {
            id = "SK_WEAPON",
            level = 2,
        },
    },
    selectable = true,
}

register.definition(categories.JOBS, definition)

return definition
