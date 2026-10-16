-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_CHAOS_KNIGHT",
    abbreviation = "CK",
    name = "Chaos Knight",
    strength = 4,
    intelligence = 4,
    dexterity = 4,
    recommended_species = {
        "SP_HILL_ORC",
        "SP_TROLL",
        "SP_GNOLL",
        "SP_MERFOLK",
        "SP_MINOTAUR",
        "SP_BASE_DRACONIAN",
        "SP_DEMONSPAWN",
    },
    spells = mod.null,
    equipment = {
        "leather armour plus:2",
        "piece from Xom's chessboard",
    },
    weapon_choice = "WCHOICE_PLAIN",
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
            id = "SK_WEAPON",
            level = 3,
        },
    },
    selectable = true,
    starting_grants = {
        {
            kind_id = item_ids.ARM_LEATHER_ARMOUR,
            quantity = 1,
            plus = 2,
        },
        {
            kind_id = item_ids.MISC_XOMS_CHESSBOARD,
            quantity = 1,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Chaos Knights are playthings of the unpredictable Xom, and " ..
        "are subject to the\ngod's constantly changing moods.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_ZEALOT,
    menu_order = 4,
}

register.definition(categories.JOBS, definition)

return definition
