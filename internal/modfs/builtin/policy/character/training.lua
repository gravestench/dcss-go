local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local forms = require("policy.magic.effects.forms.player")
local rage = require("policy.character.rage")
local availability = require("policy.character.skill_availability")
local component = require("constants.component")
local weights = require("policy.character.training_weights")
local distributed = require("policy.character.distributed_training")

local training_rules = {}

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

function training_rules.record_practice(ctx, actor, skills, training,
    species, id)
    if availability.forbidden_skill(ctx, actor, id) then
        return
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

function training_rules.change(ctx, actor, skills, training, species,
    id, focus)
    if distributed.active(ctx, actor) or
        availability.forbidden_skill(ctx, actor, id) then
        return false
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

    return true
end

local function trainable(ctx, actor, skill, training)
    local setting = weights.setting(training, skill.id)

    return setting and setting.enabled and skill.level < 27 and
        not availability.forbidden_skill(ctx, actor, skill.id)
end

local function train_chunk(ctx, actor, skill, training, species, budget)
    if not trainable(ctx, actor, skill, training) then
        return 0
    end

    local cost = formulas.skill_point_cost(training.cost_level)
    local aptitude = formulas.effective_skill_aptitude(ctx, actor,
        species, skill.id)
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

local function spend_batch(ctx, actor, skills, training, species)
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
                    ctx, actor, skills[index], training, species,
                    math.min(shares[index], remaining))

                if spent == 0 then
                    break
                end

                shares[index] = shares[index] - spent
                remaining = remaining - spent

                if not trainable(ctx, actor, skills[index], training) then
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

        if not chosen or not trainable(ctx, actor, skills[chosen], training) then
            chosen = weights.choose(ctx, weights.scaled(skills, training))
        end

        if not chosen then
            break
        end

        local spent = train_chunk(ctx, actor, skills[chosen], training,
            species, remaining)

        if spent == 0 then
            break
        end

        remaining = remaining - spent
        shares[chosen] = 0
    end

    return batch_xp - remaining
end

function training_rules.update(ctx, actor)
    local skills_component = ctx:get(actor, component.SKILLS)
    local training = ctx:get(actor, component.SKILL_TRAINING)

    if not skills_component or not training then
        error("player lacks skill training state")
    end

    local player = ctx:get(actor, component.PLAYER)

    if not player then
        error("player has no selected species")
    end

    local species = catalog.get("species", player.species_id)
    local skills = skills_component.entries

    for _, id in ipairs(ctx:signals("practice")) do
        training_rules.record_practice(ctx, actor, skills, training,
            species, id)
    end

    local fighting_before = find_skill(skills, "SK_FIGHTING")
    local points_before = fighting_before and fighting_before.points or 0

    if distributed.active(ctx, actor) then
        while distributed.spend(ctx, actor, skills, training, species) > 0 do
        end
    else
        while spend_batch(ctx, actor, skills, training, species) > 0 do
        end
    end

    skills_component.entries = skills
    ctx:set(actor, component.SKILLS, skills_component)
    ctx:set(actor, component.SKILL_TRAINING, training)
    local fighting_after = find_skill(skills, "SK_FIGHTING")

    if fighting_after and fighting_after.points ~= points_before then
        local progress = ctx:get(actor, component.PROGRESSION)
        local health = ctx:get(actor, component.HEALTH)
        local regeneration = ctx:get(actor, component.REGENERATION)

        if not progress or not health or not regeneration then
            error("player lacks Fighting HP state")
        end

        local drain = ctx:get(actor, "status.drain")
        local drain_loss = drain and drain.amount or 0
        local base_hp = math.max(1,
            formulas.max_hp(ctx, actor, progress.level, species, skills) - drain_loss)

        formulas.rescale_health(health, regeneration,
            rage.scale_hp(ctx, actor,
                forms.scale_hp(ctx, actor, base_hp)))
        ctx:set(actor, component.HEALTH, health)
        ctx:set(actor, component.REGENERATION, regeneration)
    end

    local progress = ctx:get(actor, component.PROGRESSION)
    local magic = ctx:get(actor, component.MAGIC)

    if not progress or not magic then
        error("player lacks MP training state")
    end

    local maximum = formulas.max_mp(ctx, actor, progress.level, species, skills)

    if magic.max ~= maximum then
        -- Source calc_mp() preserves current MP when a skill changes.
        magic.max = maximum
        magic.current = math.min(magic.current, maximum)
        ctx:set(actor, component.MAGIC, magic)
    end
end

function training_rules.training_mode(ctx, input)
    local actor = ctx:player()
    local training = ctx:get(actor, component.SKILL_TRAINING)

    if not training then
        error("player has no skill training")
    end

    training.manual = distributed.active(ctx, actor) or input.manual
    ctx:set(actor, component.SKILL_TRAINING, training)

    return { changed = true }
end

register.policy({
    id = "character.training_mode",
    run = training_rules.training_mode,
})

function training_rules.training_change(ctx, input)
    local actor = ctx:player()
    local player = ctx:get(actor, component.PLAYER)

    if not player then
        error("player has no selected species")
    end

    local skills = ctx:get(actor, component.SKILLS)
    local training = ctx:get(actor, component.SKILL_TRAINING)

    if not skills or not training then
        error("player lacks skill training state")
    end

    local species = catalog.get("species", player.species_id)
    local changed = training_rules.change(ctx, actor, skills.entries,
        training, species, input.id, input.focus)

    if not changed then
        return {
            changed = false,
            message = "You cannot train that skill.",
        }
    end

    ctx:set(actor, component.SKILLS, skills)
    ctx:set(actor, component.SKILL_TRAINING, training)

    return { changed = true }
end

register.policy({
    id = "character.training_change",
    run = training_rules.training_change,
})

function training_rules.training_percent(ctx, _)
    local actor = ctx:player()
    local skills = ctx:get(actor, component.SKILLS)
    local training = ctx:get(actor, component.SKILL_TRAINING)

    if not skills or not training then
        error("player lacks skill training state")
    end

    local scaled

    if distributed.active(ctx, actor) then
        scaled = distributed.percent(ctx, actor, skills.entries, training)
    else
        scaled = weights.scaled(skills.entries, training)
    end
    local percent = {}

    for index, skill in ipairs(skills.entries) do
        percent[skill.id] = scaled[index]
    end

    return percent
end

register.policy({
    id = "character.training_percent",
    run = training_rules.training_percent,
})

function training_rules.training_controls(ctx)
    return {
        adjustable = not distributed.active(ctx, ctx:player()),
    }
end

register.policy({
    id = "character.training_controls",
    run = training_rules.training_controls,
})

return training_rules
