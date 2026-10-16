-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_ARTIFICER",
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
    starting_grants = {
        {
            kind_id = item_ids.WPN_CLUB,
            quantity = 1,
        },
        {
            kind_id = item_ids.ARM_LEATHER_ARMOUR,
            quantity = 1,
        },
        {
            kind_id = item_ids.WAND_FLAME,
            quantity = 1,
            charges = 15,
        },
        {
            kind_id = item_ids.WAND_CHARMING,
            quantity = 1,
            charges = 15,
            no_exclude = true,
        },
        {
            kind_id = item_ids.WAND_ICEBLAST,
            quantity = 1,
            charges = 5,
            no_exclude = true,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Artificers start with a few magic wands and a club. They'll " ..
        "need to find better\nweapons and armour before their wands " ..
        "run out.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_ADVENTURER,
    menu_order = 1,
}

register.definition(categories.JOBS, definition)

return definition
