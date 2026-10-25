-- Gladiator (JOB_GLADIATOR) is a character start with 3 fixed item grants in
-- this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_GLADIATOR",
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
    -- Gladiator begins with these training levels before species aptitudes affect
    -- future training.
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
    -- These 3 grants create actual starting inventory for Gladiator; weapon choice
    -- may add another item.
    starting_grants = {
        {
            kind_id = item_ids.ARM_LEATHER_ARMOUR,
            quantity = 1,
        },
        {
            kind_id = item_ids.ARM_HELMET,
            quantity = 1,
        },
        {
            kind_id = item_ids.MI_THROWING_NET,
            quantity = 3,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Gladiators are ready for the arena with light armour, a " ..
        "weapon of their choice,\nand a few throwing weapons and nets.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_WARRIOR,
    menu_order = 2,
}

register.definition(categories.JOBS, definition)

return definition
