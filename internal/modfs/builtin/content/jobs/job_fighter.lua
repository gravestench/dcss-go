-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

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
        "potion of might",
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
            kind_id = item_ids.ARM_SCALE_MAIL,
            quantity = 1,
        },
        {
            kind_id = item_ids.ARM_BUCKLER,
            quantity = 1,
        },
        {
            kind_id = item_ids.POT_MIGHT,
            quantity = 1,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Fighters are equipped with armour and shield, as well as a " ..
        "weapon of their\nchoice and a potion of might.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_WARRIOR,
    menu_order = 1,
}

register.definition(categories.JOBS, definition)

return definition
