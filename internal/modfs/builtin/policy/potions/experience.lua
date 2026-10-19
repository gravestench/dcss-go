local catalog = require("policy.catalog")
local component = require("constants.component")
local formulas = require("policy.character.formulas")
local experience_limit = require("policy.character.experience_limit")
local advancement = require("policy.character.advancement")
local distributed = require("policy.character.distributed_training")
local training_rules = require("policy.character.training")

local experience = {}

-- Source: player.cc:adjust_level. Preserve the fraction of progress
-- through the current XL when moving to the next XL band.
function experience.adjusted_total(total, current, target, aptitude)
    local old_min = formulas.experience_needed(current, aptitude)
    local old_max = formulas.experience_needed(current + 1, aptitude)
    local new_min = formulas.experience_needed(target, aptitude)
    local new_max = formulas.experience_needed(target + 1, aptitude)

    return new_min + math.floor((new_max - new_min) *
        (total - old_min) / (old_max - old_min))
end

-- Expose pending skill XP only after an Experience potion has created a choice.
function experience.pending(ctx, player)
    local state = ctx:get(player, component.POTION_EXPERIENCE)

    return state and state.pending_skill_xp or 0
end

-- Update both level XP and training XP together so the drink cannot leave progression ledgers out of sync.
-- Example: Experience writes both progression and skill-training XP ledgers in one grant.
function experience.grant(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local progress = ctx:get(player, component.PROGRESSION)
    local training = ctx:get(player, component.SKILL_TRAINING)

    if not identity or not progress or not training then
        error("experience potion requires player progression and training")
    end

    local species = catalog.get("species", identity.species_id)
    local maximum = experience_limit.max_level(ctx, player)
    local old_level = progress.level
    local old_total = progress.total_xp
    local state = ctx:get(player, component.POTION_EXPERIENCE) or {
        untrained_level_xp = 0,
        bonus_skill_xp = 0,
        pending_skill_xp = 0,
    }
    local result = "A flood of memories washes over you."

    if old_level < maximum then
        local target = old_level + 1

        if target == maximum then
            progress.total_xp = math.max(old_total,
                formulas.experience_needed(maximum, species.xp))
        else
            progress.total_xp = experience.adjusted_total(old_total,
                old_level, target, species.xp)
        end

        state.untrained_level_xp = state.untrained_level_xp +
            progress.total_xp - old_total
        ctx:set(player, component.PROGRESSION, progress)
        result = "You feel more experienced!"
    end

    -- potion.cc computes this before its deferred level_change(), so it
    -- uses the level at which the potion was drunk.
    local bonus = 7500 * old_level

    state.bonus_skill_xp = state.bonus_skill_xp + bonus

    if distributed.active(ctx, player) then
        training.available_xp = training.available_xp + bonus
        ctx:set(player, component.SKILL_TRAINING, training)
    else
        state.pending_skill_xp = state.pending_skill_xp + bonus
    end

    if ctx:has(player, component.POTION_EXPERIENCE) then
        ctx:set(player, component.POTION_EXPERIENCE, state)
    else
        ctx:add(player, component.POTION_EXPERIENCE, state)
    end

    advancement.advance(ctx, player)

    return result
end

-- Apply the selected skill allocation against the saved pending amount.
function experience.choose(ctx, player, id)
    local state = ctx:get(player, component.POTION_EXPERIENCE)

    if not state or state.pending_skill_xp <= 0 then
        return {
            spent = 0,
            pending = 0,
            message = "No potion experience remains to allocate.",
        }
    end

    local spent = training_rules.spend_experience(ctx, player, id,
        state.pending_skill_xp)

    if spent == 0 then
        return {
            spent = 0,
            pending = state.pending_skill_xp,
            message = "That skill cannot receive more experience.",
        }
    end

    state.pending_skill_xp = state.pending_skill_xp - spent

    local training = ctx:get(player, component.SKILL_TRAINING)
    local cost = formulas.skill_point_cost(training.cost_level)

    if state.pending_skill_xp < cost then
        training.available_xp = training.available_xp +
            state.pending_skill_xp
        state.pending_skill_xp = 0
        ctx:set(player, component.SKILL_TRAINING, training)
    end

    ctx:set(player, component.POTION_EXPERIENCE, state)

    return {
        spent = spent,
        pending = state.pending_skill_xp,
    }
end

-- Adapt the choice screen's input into the Experience policy call.
function experience.choose_policy(ctx, input)
    return experience.choose(ctx, ctx:player(), input.id)
end

register.policy({
    id = "character.potion_experience_choose",
    run = experience.choose_policy,
})

return experience
