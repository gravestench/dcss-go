-- Example: Gnoll training includes every allowed skill while Distributed Training is active.
local component = require("constants.component")
local formulas = require("policy.character.formulas")
local availability = require("policy.character.skill_availability")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local order = require("data.skill_order")
local weights = require("policy.character.training_weights")

local distributed = {}

-- Use the effective mutation level so form and suppression rules affect Gnoll training.
function distributed.active(ctx, player)
    return levels.effective(ctx, player,
        mutations.MUT_DISTRIBUTED_TRAINING) > 0
end

-- Add every usable species skill before assigning initial distributed-training weights.
function distributed.include_skills(skills, species)
    local found = {}

    for _, skill in ipairs(skills) do
        found[skill.id] = true
    end

    for _, id in ipairs(order.all()) do
        local aptitude = species.aptitudes[id]

        if aptitude and aptitude.allowed and not found[id] then
            skills[#skills + 1] = {
                id = id,
                level = 0,
                points = 0,
            }
        end
    end
end

-- Switch saved training controls only when the mutation is actually active.
function distributed.activate(ctx, player)
    if not distributed.active(ctx, player) then
        return
    end

    local identity = ctx:get(player, component.PLAYER)
    local skills = ctx:get(player, component.SKILLS)
    local training = ctx:get(player, component.SKILL_TRAINING)

    if not identity or not skills or not training then
        error("player lacks distributed training state")
    end

    local species = require("policy.catalog").get("species",
        identity.species_id)
    distributed.include_skills(skills.entries, species)
    local settings = {}

    for _, setting in ipairs(training.settings) do
        settings[setting.id] = setting
        setting.enabled = true
        setting.focused = false
    end

    for _, skill in ipairs(skills.entries) do
        if not settings[skill.id] then
            training.settings[#training.settings + 1] = {
                id = skill.id,
                enabled = true,
                focused = false,
            }
        end
    end

    training.manual = true
    ctx:set(player, component.SKILLS, skills)
    ctx:set(player, component.SKILL_TRAINING, training)
end

-- Build one ordered bundle from usable skills; forbidden skills cannot dilute the split.
local function candidates(ctx, player, skills, training, species)
    local entries = {}
    local by_id = {}
    local settings = {}
    local all = order.all()
    local usable = 0

    for _, skill in ipairs(skills) do
        by_id[skill.id] = skill
    end

    for _, setting in ipairs(training.settings) do
        settings[setting.id] = setting
    end

    for _, id in ipairs(all) do
        local aptitude = species.aptitudes[id]
        local forbidden = availability.forbidden_skill(ctx, player, id)

        if aptitude and aptitude.allowed and not forbidden then
            usable = usable + 1

            local skill = by_id[id]
            local setting = settings[id]

            if skill and setting and setting.enabled and skill.level < 27 then
                entries[#entries + 1] = skill
            end
        end
    end

    return entries, #all, usable
end

-- Randomized cost remainders use the skill stream so fractional bundle costs stay unbiased.
local function rounded_cost(ctx, base, total, usable)
    local product = base * total
    local whole = math.floor(product / usable)
    local remainder = product % usable

    if remainder > 0 and ctx:random("skill", usable) < remainder then
        return whole + 1
    end

    return whole
end

-- Bound spending before the cost level can change, then recalculate on the next batch.
local function maximum_batch_cost(training, count, total, usable)
    local spent = training.spent_xp
    local cost = 0

    for _ = 1, count do
        local level = formulas.skill_cost_level(spent)
        local base = formulas.skill_point_cost(level)
        local maximum = math.ceil(base * total / usable)
        cost = cost + maximum
        spent = spent + maximum
    end

    return cost
end

-- Source: skills.cc:_gnoll_total_skill_cost and _train_skills. A full
-- bundle gives one point to every usable skill in reverse source order.
-- Advance every usable Gnoll skill in source order and charge its rounded share.
function distributed.spend(ctx, player, skills, training, species)
    local entries, total, usable = candidates(ctx, player,
        skills, training, species)

    if usable == 0 or #entries == 0 then
        return 0
    end

    local maximum = maximum_batch_cost(training, #entries, total, usable)

    if training.available_xp < maximum then
        return 0
    end

    local spent = 0

    for index = #entries, 1, -1 do
        local skill = entries[index]
        local base = formulas.skill_point_cost(training.cost_level)
        local cost = rounded_cost(ctx, base, total, usable)
        local before = skill.level
        local aptitude = formulas.effective_skill_aptitude(ctx, player,
            species, skill.id)

        skill.points = skill.points + 1
        skill.level = formulas.skill_level(skill.points, aptitude)
        training.available_xp = training.available_xp - cost
        training.spent_xp = training.spent_xp + cost
        training.cost_level = formulas.skill_cost_level(training.spent_xp)
        spent = spent + cost

        for level = before + 1, skill.level do
            ctx:emit("skill-up", "Your " .. skill.id ..
                " skill increases to level " .. level .. "!")
        end
    end

    return spent
end

-- Translate bundle weights back into visible skill percentages for the training UI.
function distributed.percent(ctx, player, skills, training)
    local scaled = weights.scaled(skills, training)

    for index, skill in ipairs(skills) do
        if availability.forbidden_skill(ctx, player, skill.id) then
            scaled[index] = 0
        end
    end

    return scaled
end

return distributed
