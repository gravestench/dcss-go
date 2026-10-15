-- Runtime definitions stay in Lua. Import artifacts have their own offline
-- validation; these checks protect the effective modded ruleset at boot.
local validation = {}

-- Skills that the bundled screens and rules can ask any species to train.
local ordinary_skills = {
    "SK_FIGHTING", "SK_SHORT_BLADES", "SK_LONG_BLADES", "SK_AXES",
    "SK_MACES_FLAILS", "SK_POLEARMS", "SK_STAVES", "SK_RANGED_WEAPONS",
    "SK_THROWING", "SK_ARMOUR", "SK_DODGING", "SK_STEALTH",
    "SK_SHIELDS", "SK_UNARMED_COMBAT", "SK_SPELLCASTING", "SK_CONJURATIONS",
    "SK_HEXES", "SK_SUMMONINGS", "SK_NECROMANCY", "SK_TRANSMUTATIONS",
    "SK_TRANSLOCATIONS", "SK_FIRE_MAGIC", "SK_ICE_MAGIC", "SK_AIR_MAGIC",
    "SK_EARTH_MAGIC", "SK_POISON_MAGIC", "SK_INVOCATIONS", "SK_EVOCATIONS",
}

local function fail(category, id, detail)
    local origin = register.origin(category, id)

    error(origin .. ": " .. category .. " " .. id .. " " .. detail)
end

local function required(category, definition, field, kind)
    local value = definition[field]

    if type(value) ~= kind then
        fail(category, definition.id, "requires " .. field .. " as " .. kind)
    end

    return value
end

local function optional_list(category, definition, field)
    local value = definition[field]

    if value == mod.null or value == nil then
        return {}
    end

    if type(value) ~= "table" then
        fail(category, definition.id, field .. " must be a list")
    end

    local count = 0

    for index in pairs(value) do
        if type(index) ~= "number" or index < 1 or index % 1 ~= 0 then
            fail(category, definition.id, field .. " must be a list")
        end

        count = count + 1
    end

    if count ~= #value then
        fail(category, definition.id, field .. " must be a contiguous list")
    end

    return value
end

local function optional_description(category, definition)
    local description = definition.description

    if description ~= nil and (type(description) ~= "string" or description == "") then
        fail(category, definition.id, "description must be nonempty text")
    end
end

local function validate_species(species)
    local id = species.id

    if not id:match("^SP_[A-Z0-9_]+$") then
        fail("species", id, "has an invalid ID")
    end

    for _, field in ipairs({
        "monster_id", "source_path", "name", "short_name",
        "habitat", "size", "undead_type",
    }) do
        if required("species", species, field, "string") == "" then
            fail("species", id, "has an empty " .. field)
        end
    end

    for _, field in ipairs({
        "xp", "hp", "mp_mod", "mr", "strength", "intelligence",
        "dexterity", "levelup_stat_frequency",
    }) do
        required("species", species, field, "number")
    end

    required("species", species, "selectable", "boolean")
    optional_description("species", species)
    local stats = optional_list("species", species, "levelup_stats")

    for _, stat in ipairs(stats) do
        if stat ~= "str" and stat ~= "int" and stat ~= "dex" then
            fail("species", id, "has an invalid levelup stat " .. tostring(stat))
        end
    end

    local aptitudes = required("species", species, "aptitudes", "table")

    for _, skill in ipairs(ordinary_skills) do
        if aptitudes[skill] == nil then
            fail("species", id, "is missing aptitude " .. skill)
        end
    end

    for skill, aptitude in pairs(aptitudes) do
        if type(skill) ~= "string" or not skill:match("^SK_[A-Z0-9_]+$") or
            type(aptitude) ~= "table" or
            type(aptitude.allowed) ~= "boolean" or type(aptitude.value) ~= "number" then
            fail("species", id, "has an invalid aptitude " .. tostring(skill))
        end

        if not aptitude.allowed and aptitude.value ~= 0 then
            fail("species", id, "has a value for untrainable " .. skill)
        end
    end

    if species.strength < 1 or species.intelligence < 1 or species.dexterity < 1 then
        fail("species", id, "has invalid starting attributes")
    end

    for _, job_id in ipairs(optional_list("species", species, "recommended_jobs")) do
        local found = pcall(register.get, "jobs", job_id)

        if not found then
            fail("species", id, "recommends missing job " .. job_id)
        end
    end
end

local function validate_job(job)
    local id = job.id

    if not id:match("^JOB_[A-Z0-9_]+$") then
        fail("jobs", id, "has an invalid ID")
    end

    for _, field in ipairs({ "source_path", "abbreviation", "name", "weapon_choice" }) do
        if required("jobs", job, field, "string") == "" then
            fail("jobs", id, "has an empty " .. field)
        end
    end

    if #job.abbreviation ~= 2 then
        fail("jobs", id, "has an invalid abbreviation")
    end

    for _, field in ipairs({ "strength", "intelligence", "dexterity" }) do
        required("jobs", job, field, "number")
    end

    required("jobs", job, "selectable", "boolean")
    optional_description("jobs", job)
    local skills = optional_list("jobs", job, "skills")
    local recommended = optional_list("jobs", job, "recommended_species")

    if job.selectable ~= (#recommended > 0) then
        fail("jobs", id, "selectability disagrees with recommendations")
    end

    if job.weapon_choice ~= "WCHOICE_NONE" and
        job.weapon_choice ~= "WCHOICE_PLAIN" and
        job.weapon_choice ~= "WCHOICE_GOOD" then
        fail("jobs", id, "has an invalid weapon choice")
    end

    for _, grant in ipairs(skills) do
        if type(grant) ~= "table" or type(grant.id) ~= "string" or
            not grant.id:match("^SK_") or type(grant.level) ~= "number" or
            grant.level < 0 or grant.level > 27 then
            fail("jobs", id, "has an invalid skill grant")
        end
    end

    for _, species_id in ipairs(recommended) do
        local found = pcall(register.get, "species", species_id)

        if not found then
            fail("jobs", id, "recommends missing species " .. species_id)
        end
    end
end

local function validate_groups(category, groups, descriptions)
    if type(groups) ~= "table" or type(descriptions) ~= "table" then
        error("data/presentation.lua: " .. category .. " menu groups and descriptions are required")
    end

    if #groups == 0 then
        error("data/presentation.lua: " .. category .. " menu has no groups")
    end

    local seen = {}

    for _, group in ipairs(groups) do
        if type(group) ~= "table" or type(group.label) ~= "string" or
            group.label == "" or type(group.ids) ~= "table" then
            error("data/presentation.lua: invalid " .. category .. " menu group")
        end

        for _, id in ipairs(group.ids) do
            if type(id) ~= "string" or seen[id] then
                error("data/presentation.lua: duplicate or invalid " .. category .. " menu ID " .. tostring(id))
            end

            seen[id] = true

            local found = pcall(register.get, category, id)

            if not found then
                error("data/presentation.lua: unknown " .. category .. " menu ID " .. id)
            end

            if type(descriptions[id]) ~= "string" or descriptions[id] == "" then
                error("data/presentation.lua: missing " .. category .. " description for " .. id)
            end
        end
    end
end

function validation.check()
    local species_ids = register.ids("species")
    local job_ids = register.ids("jobs")

    if #species_ids == 0 or #job_ids == 0 then
        error("Lua character content is incomplete")
    end

    for _, id in ipairs(species_ids) do
        validate_species(register.get("species", id))
    end

    for _, id in ipairs(job_ids) do
        validate_job(register.get("jobs", id))
    end

    local presentation = require("data.presentation")

    validate_groups("species", presentation.species_groups, presentation.species_descriptions)
    validate_groups("jobs", presentation.job_groups, presentation.job_descriptions)
end

return validation
