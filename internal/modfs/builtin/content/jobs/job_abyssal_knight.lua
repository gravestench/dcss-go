-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_ABYSSAL_KNIGHT",
    abbreviation = "AK",
    name = "Abyssal Knight",
    strength = 5,
    intelligence = 2,
    dexterity = 5,
    recommended_species = {
        "SP_HILL_ORC",
        "SP_PALENTONGA",
        "SP_TROLL",
        "SP_MERFOLK",
        "SP_BASE_DRACONIAN",
        "SP_DEMONSPAWN",
        "SP_METEORAN",
    },
    spells = mod.null,
    equipment = {
        "leather armour",
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
            id = "SK_INVOCATIONS",
            level = 2,
        },
        {
            id = "SK_WEAPON",
            level = 2,
        },
    },
    selectable = true,
    starting_grants = {
        {
            kind_id = item_ids.ARM_LEATHER_ARMOUR,
            quantity = 1,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Abyssal Knights worship Lugonu, and are sent from the Abyss " ..
        "into the Dungeon to\nspread corruption and chaos.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_ZEALOT,
    menu_order = 2,
}

register.definition(categories.JOBS, definition)

return definition
