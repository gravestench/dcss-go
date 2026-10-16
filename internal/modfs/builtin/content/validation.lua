-- Runtime definitions stay in Lua. Import artifacts have their own offline
-- validation; these checks protect the effective modded ruleset at boot.
local validation = {}
local categories = require("constants.catalog")
local books = require("ids.monster_spellbooks")
local skill_ids = require("ids.skills")
local spell_scopes = require("constants.spell_scopes")
local object_classes = require("ids.object_classes")
local item_rules = require("policy.inventory.items")
local staves = require("policy.inventory.staves")
local jewellery = require("policy.inventory.jewellery")
local weapon_choices = require("constants.weapon_choices")
local uses = require("constants.mutation_uses")
local source_population = require("data.dungeon_population").rows

local population_monsters = {}

for _, row in ipairs(source_population) do
    population_monsters[row.monster_id] = true
end

local population_curves = {
    FLAT = true,
    SEMI = true,
    PEAK = true,
    RISE = true,
    FALL = true,
}

local mutation_uses = {
    [uses.GOOD] = true,
    [uses.BAD] = true,
    [uses.JIYVA] = true,
    [uses.QAZLAL] = true,
    [uses.XOM] = true,
}

-- Skills that the bundled screens and rules can ask any species to train.
local ordinary_skills = {
    skill_ids.SK_FIGHTING, skill_ids.SK_SHORT_BLADES, skill_ids.SK_LONG_BLADES, skill_ids.SK_AXES,
    skill_ids.SK_MACES_FLAILS, skill_ids.SK_POLEARMS, skill_ids.SK_STAVES, skill_ids.SK_RANGED_WEAPONS,
    skill_ids.SK_THROWING, skill_ids.SK_ARMOUR, skill_ids.SK_DODGING, skill_ids.SK_STEALTH,
    skill_ids.SK_SHIELDS, skill_ids.SK_UNARMED_COMBAT, skill_ids.SK_SPELLCASTING, skill_ids.SK_CONJURATIONS,
    skill_ids.SK_HEXES, skill_ids.SK_SUMMONINGS, skill_ids.SK_NECROMANCY, skill_ids.SK_TRANSMUTATIONS,
    skill_ids.SK_TRANSLOCATIONS, skill_ids.SK_FIRE_MAGIC, skill_ids.SK_ICE_MAGIC, skill_ids.SK_AIR_MAGIC,
    skill_ids.SK_EARTH_MAGIC, skill_ids.SK_POISON_MAGIC, skill_ids.SK_INVOCATIONS, skill_ids.SK_EVOCATIONS,
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
        "monster_id", "name", "short_name",
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

    for _, field in ipairs({ "abbreviation", "name", "weapon_choice" }) do
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

    if job.weapon_choice ~= weapon_choices.NONE and
        job.weapon_choice ~= weapon_choices.PLAIN and
        job.weapon_choice ~= weapon_choices.GOOD then
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

    local grants = job.starting_grants

    if grants == nil then
        fail("jobs", id, "requires starting_grants")
    end

    if grants == mod.null then
        return
    end

    for _, grant in ipairs(optional_list("jobs", job, "starting_grants")) do
        if type(grant) ~= "table" or type(grant.kind_id) ~= "string" then
            fail("jobs", id, "has an invalid starting grant")
        end

        local found, item = pcall(register.get, categories.ITEMS,
            grant.kind_id)

        if not found or item.status == "removed" or
            item.status == "enum_only" then
            fail("jobs", id,
                "has unknown starting item " .. grant.kind_id)
        end

        if type(grant.quantity) ~= "number" or grant.quantity < 1 or
            grant.quantity % 1 ~= 0 then
            fail("jobs", id, "has invalid starting item quantity")
        end

        for _, field in ipairs({ "plus", "charges" }) do
            local value = grant[field]

            if value ~= nil and (type(value) ~= "number" or
                value % 1 ~= 0) then
                fail("jobs", id,
                    "has invalid starting item " .. field)
            end
        end

        if grant.ego ~= nil and type(grant.ego) ~= "string" then
            fail("jobs", id, "has invalid starting item ego")
        end

        if grant.no_exclude ~= nil and
            type(grant.no_exclude) ~= "boolean" then
            fail("jobs", id, "has invalid starting item no_exclude")
        end

        local initial_item = {
            kind_id = grant.kind_id,
            quantity = grant.quantity,
            plus = grant.plus or 0,
            charges = grant.charges or 0,
            ego = grant.ego or "",
        }
        local valid, reason = pcall(item_rules.validate, initial_item, item)

        if not valid then
            fail("jobs", id, "has invalid starting item " .. grant.kind_id ..
                ": " .. tostring(reason))
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

local function validate_early_brands()
    local brands = require("policy.combat.brands")
    local items = {}

    for _, definition in ipairs(require("policy.catalog").all("items")) do
        items[definition.id] = definition
    end

    for _, id in ipairs(require("data.early_weapons")) do
        local definition = items[id]

        if not definition or not definition.weapon then
            error("early monster weapon " .. id .. " has no definition")
        end

        for _, weight in ipairs(definition.weapon.brand_weights or {}) do
            if weight.weight > 0 then
                local ok, reason = pcall(brands.check, weight.brand_id)

                if not ok then
                    error("early monster weapon " .. id .. " has unresolved brand " ..
                        weight.brand_id .. ": " .. reason)
                end
            end
        end
    end
end

local function positive_number(category, definition, field)
    local value = required(category, definition, field, "number")

    if value <= 0 then
        fail(category, definition.id, field .. " must be positive")
    end
end

local function validate_population_row(monster, row)
    local category = categories.MONSTERS

    if type(row) ~= "table" then
        fail(category, monster.id, "population entries must be tables")
    end

    if type(row.scenario_id) ~= "string" or row.scenario_id == "" then
        fail(category, monster.id, "population scenario_id must be nonempty text")
    end

    for _, field in ipairs({ "min_depth", "max_depth", "rarity" }) do
        if type(row[field]) ~= "number" or row[field] % 1 ~= 0 or row[field] < 1 then
            fail(category, monster.id, "population " .. field .. " must be a positive integer")
        end
    end

    if row.min_depth > row.max_depth then
        fail(category, monster.id, "population min_depth exceeds max_depth")
    end

    if not population_curves[row.curve] then
        fail(category, monster.id, "population curve is unsupported")
    end
end

local function validate_spawnable_monster(monster)
    local category = categories.MONSTERS

    for _, field in ipairs({ "average_hp_10x", "speed", "hd" }) do
        positive_number(category, monster, field)
    end

    local energy = required(category, monster, "energy", "table")

    for _, field in ipairs({
        "move", "swim", "attack", "missile", "spell", "special", "item",
    }) do
        if type(energy[field]) ~= "number" or energy[field] <= 0 then
            fail(category, monster.id, "energy." .. field .. " must be positive")
        end
    end

    local attacks = required(category, monster, "attacks", "table")

    if #attacks == 0 then
        fail(category, monster.id, "attacks must include a primary attack")
    end

    for _, attack in ipairs(attacks) do
        if type(attack) ~= "table" or type(attack.type_id) ~= "string" or
            type(attack.flavour_id) ~= "string" or type(attack.damage) ~= "number" then
            fail(category, monster.id, "attacks contain an invalid attack")
        end
    end
end

local function validate_mutation(mutation)
    local category = categories.MUTATIONS
    local id = mutation.id

    if not id:match("^MUT_[A-Z0-9_]+$") then
        fail(category, id, "has an invalid ID")
    end

    if mutation.status ~= "active" and mutation.status ~= "removed" then
        fail(category, id, "has an invalid status")
    end

    local weight = required(category, mutation, "weight", "number")
    local maximum = required(category, mutation, "max_level", "number")

    if weight < 0 or weight % 1 ~= 0 then
        fail(category, id, "weight must be a nonnegative integer")
    end

    if maximum < 1 or maximum > 3 or maximum % 1 ~= 0 then
        fail(category, id, "max_level must be an integer from 1 to 3")
    end

    required(category, mutation, "form_based", "boolean")

    local name = required(category, mutation, "short_description", "string")

    if name == "" then
        fail(category, id, "short_description must be nonempty")
    end

    local uses = optional_list(category, mutation, "uses")

    for _, use in ipairs(uses) do
        if not mutation_uses[use] then
            fail(category, id, "has an invalid use flag " .. tostring(use))
        end
    end

    for _, field in ipairs({ "have", "gain", "lose" }) do
        local messages = optional_list(category, mutation, field)

        if #messages ~= 3 then
            fail(category, id, field .. " must have three level messages")
        end

        for _, message in ipairs(messages) do
            if type(message) ~= "string" then
                fail(category, id, field .. " messages must be text")
            end
        end
    end

    if mutation.tile_id ~= nil and type(mutation.tile_id) ~= "string" then
        fail(category, id, "tile_id must be text")
    end
end

local function validate_registered_catalogs()
    for _, id in ipairs(register.ids(categories.MUTATIONS)) do
        validate_mutation(register.get(categories.MUTATIONS, id))
    end

    for _, id in ipairs(register.ids(categories.MONSTERS)) do
        local monster = register.get(categories.MONSTERS, id)
        local population = optional_list(categories.MONSTERS, monster, "population")

        for _, row in ipairs(population) do
            validate_population_row(monster, row)
        end

        if monster.status == "defined" then
            required(categories.MONSTERS, monster, "name", "string")
            required(categories.MONSTERS, monster, "habitat_id", "string")

            local book_id = required(categories.MONSTERS, monster, "spellbook_id", "string")

            if book_id ~= books.MST_NO_SPELLS and book_id ~= books.MST_GHOST then
                local found = pcall(register.get, categories.MONSTER_SPELLBOOKS, book_id)

                if not found then
                    fail(categories.MONSTERS, id, "has missing spellbook_id " .. book_id)
                end
            end

            if population_monsters[id] or #population > 0 then
                validate_spawnable_monster(monster)
            end
        elseif #population > 0 then
            fail(categories.MONSTERS, id, "population requires status defined")
        end
    end

    for _, id in ipairs(register.ids(categories.SPELLS)) do
        local spell = register.get(categories.SPELLS, id)

        if spell.status == "defined" then
            required(categories.SPELLS, spell, "name", "string")
            required(categories.SPELLS, spell, "level", "number")

            if spell.player_scope ~= nil and
                spell.player_scope ~= spell_scopes.NONE and
                spell.player_scope ~= spell_scopes.BOOK and
                spell.player_scope ~= spell_scopes.INVOKED then
                fail(categories.SPELLS, id, "has invalid player_scope")
            end
        end
    end

    for _, id in ipairs(register.ids(categories.ITEMS)) do
        local item = register.get(categories.ITEMS, id)

        required(categories.ITEMS, item, "name", "string")
        required(categories.ITEMS, item, "class", "string")

        if item.class == object_classes.OBJ_WANDS then
            local spell_id = required(categories.ITEMS, item,
                "wand_spell_id", "string")
            local found = pcall(register.get, categories.SPELLS, spell_id)

            if not found then
                fail(categories.ITEMS, id,
                    "has missing wand_spell_id " .. spell_id)
            end
        elseif item.wand_spell_id ~= nil then
            fail(categories.ITEMS, id,
                "wand_spell_id requires the wand class")
        end

        if item.class == object_classes.OBJ_STAVES and
            item.status == "defined" then
            staves.weapon(item)
        end

        if item.class == object_classes.OBJ_JEWELLERY and
            item.status == "defined" then
            jewellery.effects(item)
        end
    end

    for _, id in ipairs(register.ids(categories.BRANCHES)) do
        local branch = register.get(categories.BRANCHES, id)

        required(categories.BRANCHES, branch, "short_name", "string")
        required(categories.BRANCHES, branch, "long_name", "string")
    end

    for _, id in ipairs(register.ids(categories.MONSTER_SPELLBOOKS)) do
        local book = register.get(categories.MONSTER_SPELLBOOKS, id)

        for _, slot in ipairs(optional_list(categories.MONSTER_SPELLBOOKS, book, "slots")) do
            local spell_id = slot.spell_id
            local found = type(spell_id) == "string" and
                pcall(register.get, categories.SPELLS, spell_id)

            if not found then
                fail(categories.MONSTER_SPELLBOOKS, id,
                    "has missing slots[].spell_id " .. tostring(spell_id))
            end
        end
    end
end

function validation.check()
    require("ids.catalog").finalize()

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

    validate_registered_catalogs()

    local presentation = require("data.presentation")

    validate_groups("species", presentation.species_groups, presentation.species_descriptions)
    validate_groups("jobs", presentation.job_groups, presentation.job_descriptions)
    validate_early_brands()
end

return validation
