-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

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
    starting_grants = {
        {
            kind_id = item_ids.ARM_ROBE,
            quantity = 1,
        },
        {
            kind_id = item_ids.SCR_POISON,
            quantity = 1,
        },
        {
            kind_id = item_ids.WPN_SLING,
            quantity = 1,
            plus = 1,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Arcane Marksmen carry a sling, and use magic to make their " ..
        "foes more\nvulnerable to attacks from afar.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_WARRIOR_MAGE,
    menu_order = 3,
}

register.definition(categories.JOBS, definition)

return definition
