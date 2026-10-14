local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local weights = require("policy.character.training_weights")

local training_rules = {}

local supported = {
    SK_FIGHTING = true,
    SK_SHORT_BLADES = true,
    SK_LONG_BLADES = true,
    SK_MACES_FLAILS = true,
    SK_AXES = true,
    SK_POLEARMS = true,
    SK_UNARMED_COMBAT = true,
    SK_ARMOUR = true,
    SK_DODGING = true,
    SK_SHIELDS = true,
}

training_rules.supported = supported

local function append_recent(queue, id)
    if #queue == 100 then
        table.remove(queue, 1)
    end

    queue[#queue + 1] = id
end

local function find_skill(skills, id)
    for _, skill in ipairs(skills) do
        if skill.id == id then
            return skill
        end
    end

    return nil
end

local function ensure_setting(skills, training, id)
    local setting = weights.setting(training, id)

    if not setting then
        skills[#skills + 1] = { id = id, level = 0, points = 0 }
        setting = { id = id, enabled = not training.manual, focused = false }
        training.settings[#training.settings + 1] = setting
    end

    return setting
end

function training_rules.record_practice(skills, training, species, id)
    if not supported[id] then
        error("unsupported Dungeon skill practice " .. id)
    end

    local skill = find_skill(skills, id)

    if skill and skill.level == 27 then
        return
    end

    formulas.skill_aptitude(species, id)
    local setting = ensure_setting(skills, training, id)
    append_recent(training.recent_all, id)

    if setting.enabled then
        append_recent(training.recent_practice, id)
    end
end

function training_rules.change(skills, training, species, id, focus)
    if not supported[id] then
        error("training " .. id .. " is unavailable in this Dungeon slice")
    end

    formulas.skill_aptitude(species, id)
    local setting = ensure_setting(skills, training, id)

    if focus then
        setting.focused = not setting.focused
        setting.enabled = true
    else
        setting.enabled = not setting.enabled

        if not setting.enabled then
            setting.focused = false
        end
    end
end

local function trainable(skill, training)
    local setting = weights.setting(training, skill.id)

    return setting and setting.enabled and skill.level < 27
end

local function train_chunk(ctx, skill, training, species, budget)
    if not trainable(skill, training) then
        return 0
    end

    local cost = formulas.skill_point_cost(training.cost_level)
    local aptitude = formulas.skill_aptitude(species, skill.id)
    local maximum = formulas.skill_points_needed(27, aptitude)
    local limit = math.min(2650, budget, training.available_xp)
    local points = math.min(math.floor(limit / cost), maximum - skill.points)

    if points <= 0 then
        return 0
    end

    local spent = points * cost
    skill.points = skill.points + points
    training.available_xp = training.available_xp - spent
    training.spent_xp = training.spent_xp + spent
    local level = formulas.skill_level(skill.points, aptitude)

    for next_level = skill.level + 1, level do
        ctx:emit("skill-up", "Your " .. skill.id .. " skill increases to level " .. next_level .. "!")
    end

    skill.level = level
    training.cost_level = formulas.skill_cost_level(training.spent_xp)

    return spent
end

local function shuffle(ctx, order)
    for count = #order, 2, -1 do
        local index = ctx:random("skill", count) + 1
        order[index], order[count] = order[count], order[index]
    end
end

local function batch_limit(training, cost)
    if training.cost_level == 27 then
        return training.available_xp
    end

    local next_threshold = formulas.experience_needed(training.cost_level + 1, 1)
    local until_next = 13 * next_threshold - training.spent_xp

    if until_next <= 0 then
        error("skill cost level lags spent XP")
    end

    return math.min(training.available_xp, until_next + cost - 1)
end

local function spend_batch(ctx, skills, training, species)
    local cost = formulas.skill_point_cost(training.cost_level)

    if training.available_xp < cost then
        return 0
    end

    local batch_xp = batch_limit(training, cost)
    local scaled = weights.scaled(skills, training)
    local shares = {}
    local order = {}
    local skip_first = false

    for index, weight in ipairs(scaled) do
        shares[index] = 0

        if weight > 0 then
            shares[index] = math.floor(weight * batch_xp / 100)
            order[#order + 1] = index

            if shares[index] < cost then
                skip_first = true
            end
        end
    end

    local remaining = batch_xp

    if not skip_first then
        shuffle(ctx, order)

        for _, index in ipairs(order) do
            while shares[index] > 0 do
                local spent = train_chunk(
                    ctx, skills[index], training, species, math.min(shares[index], remaining))

                if spent == 0 then
                    break
                end

                shares[index] = shares[index] - spent
                remaining = remaining - spent

                if not trainable(skills[index], training) then
                    shares[index] = 0
                end
            end
        end
    end

    while remaining > 0 do
        cost = formulas.skill_point_cost(training.cost_level)

        if remaining < cost then
            break
        end

        local chosen

        if not skip_first then
            chosen = weights.choose(ctx, shares)
        end

        if not chosen or not trainable(skills[chosen], training) then
            chosen = weights.choose(ctx, weights.scaled(skills, training))
        end

        if not chosen then
            break
        end

        local spent = train_chunk(ctx, skills[chosen], training, species, remaining)

        if spent == 0 then
            break
        end

        remaining = remaining - spent
        shares[chosen] = 0
    end

    return batch_xp - remaining
end

function training_rules.update(ctx, actor)
    local skills_component = ctx:get(actor, "core.skills")
    local training = ctx:get(actor, "core.skill_training")

    if not skills_component or not training then
        error("player lacks skill training state")
    end

    local player = ctx:get(actor, "core.player")

    if not player then
        error("player has no selected species")
    end

    local species = catalog.get("species", player.species_id)
    local skills = skills_component.entries

    for _, id in ipairs(ctx:signals("practice")) do
        training_rules.record_practice(skills, training, species, id)
    end

    local fighting_before = find_skill(skills, "SK_FIGHTING")
    local points_before = fighting_before and fighting_before.points or 0

    while spend_batch(ctx, skills, training, species) > 0 do
    end

    skills_component.entries = skills
    ctx:set(actor, "core.skills", skills_component)
    ctx:set(actor, "core.skill_training", training)
    local fighting_after = find_skill(skills, "SK_FIGHTING")

    if fighting_after and fighting_after.points ~= points_before then
        local progress = ctx:get(actor, "core.progression")
        local health = ctx:get(actor, "core.health")
        local regeneration = ctx:get(actor, "core.regeneration")

        if not progress or not health or not regeneration then
            error("player lacks Fighting HP state")
        end

        formulas.rescale_health(health, regeneration, formulas.max_hp(progress.level, species, skills))
        ctx:set(actor, "core.health", health)
        ctx:set(actor, "core.regeneration", regeneration)
    end
end

register.policy({
    id = "character.training_mode",
    run = function(ctx, input)
        local actor = ctx:player()
        local training = ctx:get(actor, "core.skill_training")

        if not training then
            error("player has no skill training")
        end

        training.manual = input.manual
        ctx:set(actor, "core.skill_training", training)

        return { changed = true }
    end,
})

register.policy({
    id = "character.training_change",
    run = function(ctx, input)
        local actor = ctx:player()
        local player = ctx:get(actor, "core.player")

        if not player then
            error("player has no selected species")
        end

        local skills = ctx:get(actor, "core.skills")
        local training = ctx:get(actor, "core.skill_training")

        if not skills or not training then
            error("player lacks skill training state")
        end

        local species = catalog.get("species", player.species_id)
        training_rules.change(skills.entries, training, species, input.id, input.focus)
        ctx:set(actor, "core.skills", skills)
        ctx:set(actor, "core.skill_training", training)

        return { changed = true }
    end,
})

register.policy({
    id = "character.training_percent",
    run = function(ctx, _)
        local actor = ctx:player()
        local skills = ctx:get(actor, "core.skills")
        local training = ctx:get(actor, "core.skill_training")

        if not skills or not training then
            error("player lacks skill training state")
        end

        local scaled = weights.scaled(skills.entries, training)
        local percent = {}

        for index, skill in ipairs(skills.entries) do
            percent[skill.id] = scaled[index]
        end

        return percent
    end,
})

return training_rules
