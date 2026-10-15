local catalog = require("policy.catalog")
local gear = require("policy.character.starting_gear")
local wanderer = require("policy.character.wanderer")
local traits = require("policy.character.traits")
local innate_spells = require("policy.character.innate_spells")
local starting_profile = require("policy.character.starting_profile")
local spell_records = require("policy.character.spell_records")

local start = {}

local religions = {
    JOB_BERSERKER = {
        god = "GOD_TROG",
        piety = 35,
    },
    JOB_CHAOS_KNIGHT = {
        god = "GOD_XOM",
        piety = 100,
    },
    JOB_ABYSSAL_KNIGHT = {
        god = "GOD_LUGONU",
        piety = 60,
    },
    JOB_CINDER_ACOLYTE = {
        god = "GOD_IGNIS",
        piety = 150,
    },
}

local function mutation(species, id)
    for _, entry in ipairs(species.mutations or {}) do
        if entry.id == id and entry.level <= 1 and entry.amount > 0 then
            return true
        end
    end

    return false
end

local function validate_weapon(species, job, weapon_id)
    if job.weapon_choice == "WCHOICE_NONE" then
        if weapon_id ~= "" then
            error(job.id .. " does not choose a starting weapon")
        end

        return
    end

    local choices = require("policy.character.weapon_options").options(species.id, job.id)

    for _, option in ipairs(choices) do
        if option.id == weapon_id then
            return
        end
    end

    error("invalid starting weapon " .. tostring(weapon_id) .. " for " .. species.id .. "/" .. job.id)
end

local function joined_mutations(species)
    local values = {}

    for _, entry in ipairs(species.mutations or {}) do
        if entry.level <= 1 and entry.amount > 0 then
            values[#values + 1] = entry.id .. ":" .. entry.amount
        end
    end

    return table.concat(values, ";")
end

local function starting_state(ctx, species, job, profile, generated)
    local initial = {}

    for _, skill in ipairs(profile.skills) do
        initial[#initial + 1] = skill.id .. ":" .. skill.points
    end

    local library = generated and generated.spells or
        (type(job.spells) == "table" and job.spells or {})
    local memorized = {}

    if #library > 0 then
        if mutation(species, "MUT_INNATE_CASTER") then
            for _, id in ipairs(library) do
                memorized[#memorized + 1] = id
            end
        else
            local first = catalog.get("spells", library[1])

            if first.level == 1 and
                traits.start_spell_usable(species, first.id) then
                memorized[1] = first.id
            end
        end
    end

    local worship = religions[job.id]
    local timeout = 0
    local future = {}

    if mutation(species, "MUT_INNATE_CASTER") then
        future = innate_spells.generate(ctx, species, memorized)
    end

    if job.id == "JOB_CHAOS_KNIGHT" then
        timeout = math.max(5,
            ctx:random("character", 40) + ctx:random("character", 40))
    end

    local origin = {
        initial_skills = table.concat(initial, ";"),
        strength_bonus = profile.attributes.strength - species.strength - job.strength,
        intelligence_bonus = profile.attributes.intelligence - species.intelligence - job.intelligence,
        dexterity_bonus = profile.attributes.dexterity - species.dexterity - job.dexterity,
        innate_mutations = joined_mutations(species),
        religion = worship and worship.god or "GOD_NO_GOD",
        piety = worship and worship.piety or 0,
        gift_timeout = timeout,
    }

    return origin, library, memorized, future
end

function start.run_start(ctx, input)
    local player = ctx:player()
    local species = catalog.get("species", input.species_id)
    local job = catalog.get("jobs", input.job_id)
    validate_weapon(species, job, input.weapon_id)
    local generated = job.id == "JOB_WANDERER" and
        wanderer.generate(ctx, species) or nil
    local grants = generated and generated.equipment or nil
    local weapon_skill = gear.give(ctx, player, species, job, input.weapon_id, grants)
    local profile = starting_profile.build(ctx, species, job,
        weapon_skill, generated)

    ctx:add(player, "core.attributes", profile.attributes)
    ctx:add(player, "core.skills", { entries = profile.skills })
    ctx:add(player, "core.skill_training", profile.training)
    ctx:add(player, "core.progression", { level = 1 })
    ctx:add(player, "core.durations", {})
    ctx:add(player, "core.regeneration", {})
    ctx:add(player, "core.health", {
        current = profile.max_hp,
        max = profile.max_hp,
    })
    ctx:add(player, "core.magic", {
        current = profile.max_mp,
        max = profile.max_mp,
    })
    local origin, library, memorized, future = starting_state(
        ctx, species, job, profile, generated)

    ctx:add(player, "character.origin", origin)
    spell_records.start(ctx, player, library, memorized, future)

    return {}
end

register.policy({
    id = "character.start",
    run = start.run_start,
})

function start.actor_speed(_, input)
    catalog.get("species", input.species_id)

    -- The source's base player action speed is 10 aut. Movement
    -- modifiers are resolved by movement rules.
    return { speed = 10 }
end

register.policy({
    id = "character.actor_speed",
    run = start.actor_speed,
})

return start
