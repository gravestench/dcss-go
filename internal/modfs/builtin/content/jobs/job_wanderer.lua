-- Wanderer (JOB_WANDERER) is a character start with 0 fixed item grants in
-- this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_WANDERER",
    abbreviation = "Wn",
    name = "Wanderer",
    strength = 0,
    intelligence = 0,
    dexterity = 0,
    recommended_species = {
        "SP_HILL_ORC",
        "SP_METEORAN",
        "SP_GNOLL",
        "SP_MERFOLK",
        "SP_BASE_DRACONIAN",
        "SP_HUMAN",
        "SP_DEMONSPAWN",
    },
    spells = mod.null,
    equipment = mod.null,
    weapon_choice = "WCHOICE_NONE",
    skills = mod.null,
    selectable = true,
    starting_grants = mod.null,
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Wanderers start with random equipment and skills.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_ADVENTURER,
    menu_order = 2,
}

register.definition(categories.JOBS, definition)

return definition
