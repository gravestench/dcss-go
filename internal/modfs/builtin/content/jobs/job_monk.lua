-- Monk (JOB_MONK) is a character start with 2 fixed item grants in this
-- definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h

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
    -- Monk begins with these training levels before species aptitudes affect
    -- future training.
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
    -- These 2 grants create actual starting inventory for Monk; weapon choice may
    -- add another item.
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
