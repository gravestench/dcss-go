-- Skald (JOB_SKALD) is a retained source job, unavailable in character selection.
-- It has no fixed starting item grants; its old stats remain catalog data.

-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")

local definition = {
    id = "JOB_SKALD",
    abbreviation = "Sk",
    name = "Skald",
    strength = 0,
    intelligence = 0,
    dexterity = 0,
    recommended_species = mod.null,
    spells = mod.null,
    equipment = mod.null,
    weapon_choice = "WCHOICE_NONE",
    skills = mod.null,
    selectable = false,
    -- These 0 grants create actual starting inventory for Skald; weapon choice may
    -- add another item.
    starting_grants = {},
}

register.definition(categories.JOBS, definition)

return definition
