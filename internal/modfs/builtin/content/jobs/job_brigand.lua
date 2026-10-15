-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "JOB_BRIGAND",
    abbreviation = "Br",
    name = "Brigand",
    strength = 3,
    intelligence = 3,
    dexterity = 6,
    recommended_species = {
        "SP_TROLL",
        "SP_SPRIGGAN",
        "SP_DEMONSPAWN",
        "SP_VAMPIRE",
        "SP_VINE_STALKER",
    },
    spells = mod.null,
    equipment = {
        "dagger plus:2",
        "robe",
        "cloak",
        "dart ego:poisoned q:9",
        "dart ego:curare q:3",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 2,
        },
        {
            id = "SK_DODGING",
            level = 1,
        },
        {
            id = "SK_STEALTH",
            level = 4,
        },
        {
            id = "SK_THROWING",
            level = 2,
        },
        {
            id = "SK_WEAPON",
            level = 2,
        },
    },
    selectable = true,
    starting_grants = {
        {
            kind_id = item_ids.WPN_DAGGER,
            quantity = 1,
            plus = 2,
        },
        {
            kind_id = item_ids.ARM_ROBE,
            quantity = 1,
        },
        {
            kind_id = item_ids.ARM_CLOAK,
            quantity = 1,
        },
        {
            kind_id = item_ids.MI_DART,
            quantity = 9,
            ego = "poisoned",
        },
        {
            kind_id = item_ids.MI_DART,
            quantity = 3,
            ego = "curare",
        },
    },
}

register.definition(categories.JOBS, definition)

return definition
