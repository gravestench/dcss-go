-- Earth Elementalist (JOB_EARTH_ELEMENTALIST) is a character start with 2
-- fixed item grants in this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_EARTH_ELEMENTALIST",
    abbreviation = "EE",
    name = "Earth Elementalist",
    strength = 0,
    intelligence = 7,
    dexterity = 5,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_SPRIGGAN",
        "SP_GARGOYLE",
        "SP_DEMIGOD",
        "SP_GHOUL",
        "SP_OCTOPODE",
    },
    spells = {
        "SPELL_SANDBLAST",
        "SPELL_PASSWALL",
        "SPELL_STONE_ARROW",
        "SPELL_PETRIFY",
    },
    equipment = {
        "robe",
        "potion of magic",
    },
    weapon_choice = "WCHOICE_NONE",
    -- Earth Elementalist begins with these training levels before species
    -- aptitudes affect future training.
    skills = {
        {
            id = "SK_TRANSMUTATIONS",
            level = 1,
        },
        {
            id = "SK_EARTH_MAGIC",
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
    -- These 2 grants create actual starting inventory for Earth Elementalist;
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
    description = "Earth Elementalists know the Sandblast spell, and can later " ..
        "learn more earthen\nspells suitable for subtle stabbing or " ..
        "brute-force blasting.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_MAGE,
    menu_order = 8,
}

register.definition(categories.JOBS, definition)

return definition
