-- Artificer (JOB_ARTIFICER) is a character start with 5 fixed item grants in
-- this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h

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
    -- Artificer begins with these training levels before species aptitudes affect
    -- future training.
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
    -- These 5 grants create actual starting inventory for Artificer; weapon choice
    -- may add another item.
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
