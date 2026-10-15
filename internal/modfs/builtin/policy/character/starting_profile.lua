-- Source-derived starting skill points, attributes, training, HP and MP.
local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local choice = require("policy.character_choice")
local equipment = require("policy.inventory.equipment")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local distributed = require("policy.character.distributed_training")

local starting_profile = {}

local function remainder_before(left, right)
    if left.value == right.value then
        return left.index < right.index
    end

    return left.value < right.value
end

local magic_schools = {
    SK_CONJURATIONS = true,
    SK_HEXES = true,
    SK_SUMMONINGS = true,
    SK_NECROMANCY = true,
    SK_TRANSLOCATIONS = true,
    SK_TRANSMUTATIONS = true,
    SK_FIRE_MAGIC = true,
    SK_ICE_MAGIC = true,
    SK_AIR_MAGIC = true,
    SK_EARTH_MAGIC = true,
    SK_POISON_MAGIC = true,
}

local armour_choice_jobs = {
    JOB_ARTIFICER = true,
    JOB_CHAOS_KNIGHT = true,
    JOB_ABYSSAL_KNIGHT = true,
}

local function starting_skills(ctx, species, job, weapon_skill, generated)
    local levels = {}
    local grant_order = {}
    local granted = {}

    for _, grant in ipairs(generated or job.skills) do
        local id = grant.id == "SK_WEAPON" and weapon_skill or grant.id

        if grant.level < 1 or grant.level > 9 then
            error("unsupported starting skill level " .. grant.level)
        end

        levels[id] = (levels[id] or 0) + grant.level

        if not granted[id] then
            grant_order[#grant_order + 1] = id
            granted[id] = true
        end
    end

    if job.id == "JOB_BERSERKER" then
        if not equipment.can_wear(ctx, ctx:player(), species,
            catalog.get("items", "ARM_ROBE")) then
            levels.SK_DODGING = (levels.SK_DODGING or 0) + 1
        else
            levels.SK_ARMOUR = (levels.SK_ARMOUR or 0) + 2
        end
    elseif armour_choice_jobs[job.id] then
        local armour = species.aptitudes.SK_ARMOUR
        local dodging = species.aptitudes.SK_DODGING

        if armour.allowed and armour.value >= dodging.value then
            levels.SK_ARMOUR = (levels.SK_ARMOUR or 0) + 1
        else
            levels.SK_DODGING = (levels.SK_DODGING or 0) + 1
        end
    end

    if mutation_levels.effective(ctx, ctx:player(),
        mutations.MUT_NO_GRASPING) > 0 then
        levels.SK_THROWING = nil

        if job.id == "JOB_FIGHTER" then
            levels.SK_UNARMED_COMBAT = (levels.SK_UNARMED_COMBAT or 0) + 2
        end
    end

    if mutation_levels.effective(ctx, ctx:player(),
        mutations.MUT_NO_ARMOUR) > 0 then
        levels.SK_SHIELDS = nil
    end

    if levels.SK_ARMOUR and
        (not equipment.can_wear(ctx, ctx:player(), species,
            catalog.get("items", "ARM_CRYSTAL_PLATE_ARMOUR")) or
            not species.aptitudes.SK_ARMOUR.allowed) then
        levels.SK_DODGING = (levels.SK_DODGING or 0) + levels.SK_ARMOUR
        levels.SK_ARMOUR = nil
    end

    if mutation_levels.effective(ctx, ctx:player(),
        mutations.MUT_INNATE_CASTER) > 0 then
        local highest = levels.SK_SPELLCASTING or 0

        for id in pairs(magic_schools) do
            highest = math.max(highest, levels[id] or 0)
            levels[id] = nil
        end

        if highest > 0 then
            levels.SK_SPELLCASTING = highest
        end
    end

    local skills = {}
    local ordered = {}

    for _, id in ipairs(grant_order) do
        if levels[id] then
            ordered[#ordered + 1] = id
        end
    end

    local additions = {}

    for id in pairs(levels) do
        if not granted[id] then
            additions[#additions + 1] = id
        end
    end

    table.sort(additions)

    for _, id in ipairs(additions) do
        ordered[#ordered + 1] = id
    end

    for _, id in ipairs(ordered) do
        local aptitude = species.aptitudes[id]

        if aptitude and aptitude.allowed then
            local points = formulas.skill_points_needed(levels[id], 0) + 1
            local level = 0

            for next_level = 1, 8 do
                if points <= formulas.skill_points_needed(next_level, aptitude.value) then
                    break
                end

                level = next_level
            end

            if (job.id == "JOB_WANDERER" or id == "SK_SPELLCASTING") and
                level < 1 then
                points = formulas.skill_points_needed(1, aptitude.value)
                level = 1
            end

            skills[#skills + 1] = {
                id = id,
                level = level,
                points = points,
            }
        end
    end

    local has_fighting = levels.SK_FIGHTING ~= nil

    if not has_fighting then
        table.insert(skills, 1, {
            id = "SK_FIGHTING",
            level = 0,
            points = 0,
        })
    end

    return skills
end

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
        order[index] = {
            index = index,
            value = remainders[index],
        }
    end

    table.sort(order, remainder_before)

    local extra = 1

    while assigned < 100 do
        local index = order[extra].index
        counts[index] = counts[index] + 1
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

function starting_profile.build(ctx, species, job, weapon_skill, generated)
    if not choice.allowed(species, job) then
        error("banned character choice " .. species.id .. "/" .. job.id)
    end

    if not species.selectable or not job.selectable then
        error("banned character choice " .. species_id .. "/" .. job_id)
    end

    local skills = starting_skills(ctx, species, job, weapon_skill,
        generated and generated.skills)

    if distributed.active(ctx, ctx:player()) then
        distributed.include_skills(skills, species)
    end

    local settings = {}
    local attributes = {
        strength = species.strength + job.strength,
        intelligence = species.intelligence + job.intelligence,
        dexterity = species.dexterity + job.dexterity,
    }

    local fields = { "strength", "intelligence", "dexterity" }

    for index, field in ipairs(fields) do
        local needed = 3 - attributes[field]

        if needed > 0 then
            local first = fields[index % 3 + 1]
            local second = fields[(index + 1) % 3 + 1]
            local donor = attributes[first] > attributes[second] and first or second
            attributes[donor] = attributes[donor] - needed
            attributes[field] = 3
        end
    end

    if generated then
        for _, field in ipairs(fields) do
            attributes[field] = attributes[field] + generated.attributes[field]
        end
    end

    for _, skill in ipairs(skills) do
        settings[#settings + 1] = {
            id = skill.id,
            enabled = true,
            focused = false,
        }
    end

    return {
        attributes = attributes,
        skills = skills,
        max_hp = formulas.max_hp(ctx, ctx:player(), 1, species, skills),
        max_mp = formulas.max_mp(ctx, ctx:player(), 1, species, skills),
        training = {
            available_xp = 0,
            spent_xp = 0,
            cost_level = 1,
            manual = distributed.active(ctx, ctx:player()),
            settings = settings,
            recent_practice = seed_queue(ctx, skills),
            recent_all = seed_queue(ctx, skills),
        },
    }
end

return starting_profile
