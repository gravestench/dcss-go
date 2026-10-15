-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")

local definition = {
    id = "JOB_HEALER",
    abbreviation = "He",
    name = "Healer",
    strength = 0,
    intelligence = 0,
    dexterity = 0,
    recommended_species = mod.null,
    spells = mod.null,
    equipment = mod.null,
    weapon_choice = "WCHOICE_NONE",
    skills = mod.null,
    selectable = false,
}

register.definition(categories.JOBS, definition)

return definition
