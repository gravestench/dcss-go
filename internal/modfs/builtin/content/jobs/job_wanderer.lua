-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")

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
}

register.definition(categories.JOBS, definition)

return definition
