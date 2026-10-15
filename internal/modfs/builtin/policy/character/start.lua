local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")

local start = {}

local fighter_species = {
    SP_HUMAN = true,
    SP_HILL_ORC = true,
    SP_DEEP_ELF = true,
    SP_MINOTAUR = true,
}

local fighter_weapons = {
    WPN_RAPIER = true,
    WPN_FLAIL = true,
    WPN_WAR_AXE = true,
    WPN_TRIDENT = true,
    WPN_LONG_SWORD = true,
    WPN_UNARMED = true,
}

function start.supported(species_id, job_id)
    return fighter_species[species_id] == true and job_id == "JOB_FIGHTER"
end

local function starting_skills(species, job, weapon_id)
    if not fighter_weapons[weapon_id] then
        error("weapon " .. weapon_id .. " is not a legal choice for " .. species.id .. "/" .. job.id)
    end

    local weapon_skill = "SK_UNARMED_COMBAT"

    if weapon_id ~= "WPN_UNARMED" then
        local kind = catalog.get("items", weapon_id)

        if kind.class ~= "OBJ_WEAPONS" or not kind.weapon_skill then
            error("weapon " .. weapon_id .. " has no usable weapon skill")
        end

        weapon_skill = kind.weapon_skill
        formulas.skill_aptitude(species, weapon_skill)
    end

    local skills = {}
    local seen = {}

    for _, grant in ipairs(job.skills) do
        local id = grant.id == "SK_WEAPON" and weapon_skill or grant.id
        local aptitude = formulas.skill_aptitude(species, id)

        if seen[id] then
            error(species.id .. "/" .. job.id .. " has duplicate starting skill " .. id)
        end

        seen[id] = true

        if grant.level < 1 or grant.level > 9 then
            error("unsupported Human starting skill level " .. grant.level)
        end

        local points = formulas.skill_points_needed(grant.level, 0) + 1
        local level = 0

        for next_level = 1, 8 do
            if points <= formulas.skill_points_needed(next_level, aptitude) then
                break
            end

            level = next_level
        end

        skills[#skills + 1] = { id = id, level = level, points = points }
    end

    return skills
end

start.starting_skills = starting_skills

local function seed_queue(ctx, skills)
    local counts = {}
    local remainders = {}
    local total = 0

    for _, skill in ipairs(skills) do
        total = total + skill.points * skill.points
    end

    if total == 0 then
        error("cannot seed training without starting points")
    end

    local assigned = 0
    local order = {}

    for index, skill in ipairs(skills) do
        local scaled = skill.points * skill.points * 100
        counts[index] = math.floor(scaled / total)
        remainders[index] = scaled % total
        assigned = assigned + counts[index]
        order[index] = index
    end

    table.sort(order, function(a, b)
        if remainders[a] == remainders[b] then
            return a < b
        end

        return remainders[a] < remainders[b]
    end)

    local extra = 1

    while assigned < 100 do
        counts[order[extra]] = counts[order[extra]] + 1
        assigned = assigned + 1
        extra = extra + 1
    end

    local queue = {}

    for remaining = 100, 1, -1 do
        local choice = ctx:random("skill", remaining)

        for index, count in ipairs(counts) do
            if choice < count then
                queue[#queue + 1] = skills[index].id
                counts[index] = count - 1
                break
            end

            choice = choice - count
        end
    end

    return queue
end

function start.profile(ctx, species_id, job_id, weapon_id)
    if not start.supported(species_id, job_id) then
        error("unsupported starting skills for " .. species_id .. "/" .. job_id)
    end

    local species = catalog.get("species", species_id)
    local job = catalog.get("jobs", job_id)

    if not species.selectable or not job.selectable then
        error("banned character choice " .. species_id .. "/" .. job_id)
    end

    local skills = starting_skills(species, job, weapon_id)
    local settings = {}

    for _, skill in ipairs(skills) do
        settings[#settings + 1] = {
            id = skill.id,
            enabled = true,
            focused = false,
        }
    end

    return {
        attributes = {
            strength = species.strength + job.strength,
            intelligence = species.intelligence + job.intelligence,
            dexterity = species.dexterity + job.dexterity,
        },
        skills = skills,
        max_hp = formulas.max_hp(1, species, skills),
        max_mp = formulas.max_mp(1, species),
        training = {
            available_xp = 0,
            spent_xp = 0,
            cost_level = 1,
            manual = false,
            settings = settings,
            recent_practice = seed_queue(ctx, skills),
            recent_all = seed_queue(ctx, skills),
        },
    }
end

register.policy({
    id = "character.start",
    run = function(ctx, input)
        local profile = start.profile(ctx, input.species_id, input.job_id, input.weapon_id)
        local player = ctx:player()

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

        return {}
    end,
})

register.policy({
    id = "character.supported_start",
    run = function(_, input)
        return { supported = start.supported(input.species_id, input.job_id) }
    end,
})

register.policy({
    id = "character.actor_speed",
    run = function(_, input)
        catalog.get("species", input.species_id)

        -- The source's base player speed is 10 aut. Species modifiers
        -- belong here when their starts become playable.
        return { speed = 10 }
    end,
})

register.policy({
    id = "character.supported_starts",
    run = function(_, input)
        local supported = {}

        for index, pair in ipairs(input.pairs) do
            supported[index] = start.supported(pair.species_id, pair.job_id)
        end

        return { supported = supported }
    end,
})

return start
