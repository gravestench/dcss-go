-- Fighter (JOB_FIGHTER) is a character start with 3 fixed item grants in this
-- definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

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
    -- Fighter begins with these training levels before species aptitudes affect
    -- future training.
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
    -- These 3 grants create actual starting inventory for Fighter; weapon choice
    -- may add another item.
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
