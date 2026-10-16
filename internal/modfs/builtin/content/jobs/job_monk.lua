-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_MONK",
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
    starting_grants = {
        {
            kind_id = item_ids.ARM_ROBE,
            quantity = 1,
        },
        {
            kind_id = item_ids.POT_AMBROSIA,
            quantity = 1,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Monks start with a simple weapon of their choice and a " ..
        "potion of divine ambrosia,\nand gain additional piety with " ..
        "the first god they worship.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_WARRIOR,
    menu_order = 3,
}

register.definition(categories.JOBS, definition)

return definition
