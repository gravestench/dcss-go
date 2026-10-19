-- Hunter (JOB_HUNTER) is a character start with 3 fixed item grants in this
-- definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_HUNTER",
    abbreviation = "Hu",
    name = "Hunter",
    strength = 3,
    intelligence = 1,
    dexterity = 8,
    recommended_species = {
        "SP_HILL_ORC",
        "SP_MINOTAUR",
        "SP_GNOLL",
        "SP_KOBOLD",
        "SP_SPRIGGAN",
    },
    spells = mod.null,
    equipment = {
        "leather armour",
        "scroll of immolation",
        "shortbow",
    },
    weapon_choice = "WCHOICE_NONE",
    -- Hunter begins with these training levels before species aptitudes affect
    -- future training.
    skills = {
        {
            id = "SK_FIGHTING",
            level = 2,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_STEALTH",
            level = 1,
        },
        {
            id = "SK_WEAPON",
            level = 4,
        },
    },
    selectable = true,
    -- These 3 grants create actual starting inventory for Hunter; weapon choice
    -- may add another item.
    starting_grants = {
        {
            kind_id = item_ids.ARM_LEATHER_ARMOUR,
            quantity = 1,
        },
        {
            kind_id = item_ids.SCR_IMMOLATION,
            quantity = 1,
        },
        {
            kind_id = item_ids.WPN_SHORTBOW,
            quantity = 1,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Hunters carry a shortbow, light armour and a scroll of " ..
        "immolation.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_WARRIOR,
    menu_order = 4,
}

register.definition(categories.JOBS, definition)

return definition
