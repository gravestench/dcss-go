-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")

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
}

register.definition(categories.JOBS, definition)

return definition
