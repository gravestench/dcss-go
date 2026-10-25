-- Delver (JOB_DELVER) is a character start with 6 fixed item grants in this
-- definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_DELVER",
    abbreviation = "De",
    name = "Delver",
    strength = 4,
    intelligence = 2,
    dexterity = 6,
    recommended_species = {
        "SP_FELID",
        "SP_SPRIGGAN",
        "SP_KOBOLD",
        "SP_VAMPIRE",
        "SP_GNOLL",
    },
    spells = mod.null,
    equipment = {
        "leather armour",
        "scroll of fog no_exclude",
        "scroll of magic mapping",
        "scroll of fear",
        "potion of haste",
        "wand of digging charges:3",
    },
    weapon_choice = "WCHOICE_PLAIN",
    -- Delver begins with these training levels before species aptitudes affect
    -- future training.
    skills = {
        {
            id = "SK_FIGHTING",
            level = 3,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_STEALTH",
            level = 5,
        },
        {
            id = "SK_WEAPON",
            level = 2,
        },
    },
    selectable = true,
    -- These 6 grants create actual starting inventory for Delver; weapon choice
    -- may add another item.
    starting_grants = {
        {
            kind_id = item_ids.ARM_LEATHER_ARMOUR,
            quantity = 1,
        },
        {
            kind_id = item_ids.SCR_FOG,
            quantity = 1,
            no_exclude = true,
        },
        {
            kind_id = item_ids.SCR_MAGIC_MAPPING,
            quantity = 1,
        },
        {
            kind_id = item_ids.SCR_FEAR,
            quantity = 1,
        },
        {
            kind_id = item_ids.POT_HASTE,
            quantity = 1,
        },
        {
            kind_id = item_ids.WAND_DIGGING,
            quantity = 1,
            charges = 3,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Delvers start their quest five levels below the surface. A " ..
        "set of powerful magic\nitems helps them survive the dangerous " ..
        "journey upward.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_ADVENTURER,
    menu_order = 3,
}

register.definition(categories.JOBS, definition)

return definition
