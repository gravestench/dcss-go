-- Character menu groups preserve source order and reject invalid metadata from definitions.

local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local groups = require("constants.menu_groups")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local menu = require("policy.character.menu")
local species = require("ids.species")
local validation = require("content.validation")

local test = {}

-- Group sizes and order are menu content, rather than catalog load order.
local function source_groups()
    local presentation = menu.presentation()
    local species_groups = presentation.species_groups
    local job_groups = presentation.job_groups

    harness.equal(#species_groups, 3, "species group count")
    harness.equal(#job_groups, 5, "job group count")
    harness.equal(species_groups[1].label, groups.SPECIES_SIMPLE,
        "first species group")
    harness.equal(species_groups[2].label, groups.SPECIES_INTERMEDIATE,
        "second species group")
    harness.equal(species_groups[3].label, groups.SPECIES_ADVANCED,
        "third species group")
    harness.equal(job_groups[1].label, groups.JOB_WARRIOR,
        "first job group")
    harness.equal(job_groups[5].label, groups.JOB_MAGE,
        "last job group")

    for _, group in ipairs(species_groups) do
        harness.equal(#group.ids, 9, "source species group size")
    end

    local job_sizes = { 5, 3, 4, 4, 9 }

    for index, group in ipairs(job_groups) do
        harness.equal(#group.ids, job_sizes[index],
            "source job group size " .. index)
    end

    harness.equal(species_groups[1].ids[1], species.SP_HILL_ORC,
        "source species order")
    harness.equal(species_groups[2].ids[1], species.SP_HUMAN,
        "Human source position")
    harness.equal(job_groups[1].ids[1], jobs.JOB_FIGHTER,
        "source job order")
    harness.equal(job_groups[5].ids[9], jobs.JOB_VENOM_MAGE,
        "last mage position")
end

-- The detail pane reads species and job descriptions from live definitions.
local function descriptions_come_from_definitions()
    local presentation = menu.presentation()
    local human = catalog.get(categories.SPECIES, species.SP_HUMAN)
    local fighter = catalog.get(categories.JOBS, jobs.JOB_FIGHTER)

    harness.truthy(human.description and human.description ~= "",
        "Human definition lacks menu description")
    harness.truthy(fighter.description and fighter.description ~= "",
        "Fighter definition lacks menu description")
    harness.equal(presentation.species_descriptions[species.SP_HUMAN],
        human.description, "Human menu description owner")
    harness.equal(presentation.job_descriptions[jobs.JOB_FIGHTER],
        fighter.description, "Fighter menu description owner")
end

-- Corrupt menu metadata on a live definition and require validation to fail,
-- so a mod cannot create ambiguous category ordering or empty descriptions.
local function invalid_menu_fields_are_rejected()
    local human = catalog.get(categories.SPECIES, species.SP_HUMAN)
    local kobold = catalog.get(categories.SPECIES, species.SP_KOBOLD)
    human.difficulty_priority = kobold.difficulty_priority

    local valid, reason = pcall(validation.menu_fields,
        categories.SPECIES, { human, kobold }, groups.species,
        "difficulty", "difficulty_priority")

    harness.falsy(valid, "duplicate menu order was accepted")
    harness.truthy(reason:find("duplicates menu order", 1, true),
        "duplicate order error does not name the rule")

    human = catalog.get(categories.SPECIES, species.SP_HUMAN)
    human.description = nil
    valid, reason = pcall(validation.menu_fields,
        categories.SPECIES, { human }, groups.species,
        "difficulty", "difficulty_priority")

    harness.falsy(valid, "missing menu description was accepted")
    harness.truthy(reason:find("requires a menu description", 1, true),
        "description error does not name the rule")
end

-- Added species join the modded group without shifting bundled menu pages.
local function added_group_member_stays_on_modded_page()
    local definitions = catalog.all(categories.SPECIES)
    local human = catalog.get(categories.SPECIES, species.SP_HUMAN)
    local addition = {}

    for field, value in pairs(human) do
        addition[field] = value
    end

    addition.id = human.id .. "_MOD"
    addition.difficulty = groups.SPECIES_INTERMEDIATE
    addition.difficulty_priority = 1
    definitions[#definitions + 1] = addition

    local choice_groups = menu.species_choices(definitions)

    harness.equal(#choice_groups[2].ids, groups.species_capacities[2],
        "pinned group exceeded its screen height")
    harness.equal(choice_groups[4].label, groups.MODDED_SPECIES,
        "overflow has no modded page")
    harness.equal(choice_groups[4].ids[1], addition.id,
        "new group member did not reach modded page")
end

-- Check groups, descriptions, validation, and modded pages together because
-- the character menu derives all four from the same content definitions.
function test.run()
    source_groups()
    descriptions_come_from_definitions()
    invalid_menu_fields_are_rejected()
    added_group_member_stays_on_modded_page()
end

return test
