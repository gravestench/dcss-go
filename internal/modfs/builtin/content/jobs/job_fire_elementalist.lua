-- Fire Elementalist (JOB_FIRE_ELEMENTALIST) is a character start with 2 fixed
-- item grants in this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_FIRE_ELEMENTALIST",
    abbreviation = "FE",
    name = "Fire Elementalist",
    strength = 0,
    intelligence = 7,
    dexterity = 5,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_HILL_ORC",
        "SP_NAGA",
        "SP_TENGU",
        "SP_DEMIGOD",
        "SP_GARGOYLE",
        "SP_DJINNI",
    },
    spells = {
        "SPELL_FOXFIRE",
        "SPELL_SCORCH",
        "SPELL_CONJURE_FLAME",
        "SPELL_INNER_FLAME",
        "SPELL_FLAME_WAVE",
    },
    equipment = {
        "robe",
        "potion of magic",
    },
    weapon_choice = "WCHOICE_NONE",
    -- Fire Elementalist begins with these training levels before species aptitudes
    -- affect future training.
    skills = {
        {
            id = "SK_CONJURATIONS",
            level = 1,
        },
        {
            id = "SK_FIRE_MAGIC",
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
            level = 2,
        },
    },
    selectable = true,
    -- These 2 grants create actual starting inventory for Fire Elementalist;
    -- weapon choice may add another item.
    starting_grants = {
        {
            kind_id = item_ids.ARM_ROBE,
            quantity = 1,
        },
        {
            kind_id = item_ids.POT_MAGIC,
            quantity = 1,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Fire Elementalists have learned the Foxfire spell. Their " ..
        "other starting spells\nare likewise focused on fiery " ..
        "destruction.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_MAGE,
    menu_order = 5,
}

register.definition(categories.JOBS, definition)

return definition
