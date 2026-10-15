-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "JOB_ENCHANTER",
    abbreviation = "En",
    name = "Enchanter",
    strength = 0,
    intelligence = 7,
    dexterity = 5,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_FELID",
        "SP_KOBOLD",
        "SP_SPRIGGAN",
        "SP_NAGA",
        "SP_VAMPIRE",
    },
    spells = {
        "SPELL_HIBERNATION",
        "SPELL_CONFUSING_TOUCH",
        "SPELL_TUKIMAS_DANCE",
        "SPELL_DAZZLING_FLASH",
    },
    equipment = {
        "dagger plus:1",
        "robe",
        "potion of invisibility q:2",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_WEAPON",
            level = 1,
        },
        {
            id = "SK_HEXES",
            level = 3,
        },
        {
            id = "SK_SPELLCASTING",
            level = 2,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_STEALTH",
            level = 3,
        },
    },
    selectable = true,
    starting_grants = {
        {
            kind_id = item_ids.WPN_DAGGER,
            quantity = 1,
            plus = 1,
        },
        {
            kind_id = item_ids.ARM_ROBE,
            quantity = 1,
        },
        {
            kind_id = item_ids.POT_INVISIBILITY,
            quantity = 2,
        },
    },
}

register.definition(categories.JOBS, definition)

return definition
