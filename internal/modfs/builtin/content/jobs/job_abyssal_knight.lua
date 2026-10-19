-- Abyssal Knight (JOB_ABYSSAL_KNIGHT) is a character start with 1 fixed item
-- grants in this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

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
    -- Abyssal Knight begins with these training levels before species aptitudes
    -- affect future training.
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
    -- These 1 grants create actual starting inventory for Abyssal Knight; weapon
    -- choice may add another item.
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
