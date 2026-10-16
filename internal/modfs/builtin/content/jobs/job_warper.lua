-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_WARPER",
    abbreviation = "Wr",
    name = "Warper",
    strength = 3,
    intelligence = 5,
    dexterity = 4,
    recommended_species = {
        "SP_FELID",
        "SP_METEORAN",
        "SP_SPRIGGAN",
        "SP_PALENTONGA",
        "SP_BASE_DRACONIAN",
    },
    spells = {
        "SPELL_BLINK",
        "SPELL_BECKONING",
        "SPELL_GRAVITAS",
        "SPELL_TELEPORT_OTHER",
        "SPELL_MANIFOLD_ASSAULT",
    },
    equipment = {
        "leather armour",
        "scroll of blinking",
        "boomerang ego:dispersal q:7",
    },
    weapon_choice = "WCHOICE_PLAIN",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 2,
        },
        {
            id = "SK_ARMOUR",
            level = 1,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_SPELLCASTING",
            level = 2,
        },
        {
            id = "SK_TRANSLOCATIONS",
            level = 3,
        },
        {
            id = "SK_THROWING",
            level = 1,
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
        {
            kind_id = item_ids.SCR_BLINKING,
            quantity = 1,
        },
        {
            kind_id = item_ids.MI_BOOMERANG,
            quantity = 7,
            ego = "dispersal",
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Warpers start with a weapon of their choice, a scroll of " ..
        "blinking, boomerangs\nof dispersal, and some Translocation " ..
        "spells in their library.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_WARRIOR_MAGE,
    menu_order = 2,
}

register.definition(categories.JOBS, definition)

return definition
