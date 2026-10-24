-- Example: A level gain reads the saved species choice before adding that species' attribute growth.
local catalog = require("policy.catalog")
local component = require("constants.component")
local formulas = require("policy.character.formulas")
local experience_limit = require("policy.character.experience_limit")
local extra_lives = require("policy.character.extra_lives")
local spell_records = require("policy.character.spell_records")
local mutation_transition = require("policy.mutations.transition")
local forms = require("policy.magic.effects.forms.player")
local rage = require("policy.character.rage")
local availability = require("policy.character.skill_availability")

local advancement = {}

local stat_fields = {
    str = "strength",
    int = "intelligence",
    dex = "dexterity",
}

-- Read the saved player choice so level gains use the species selected at creation.
local function selected_species(ctx, actor)
    local player = ctx:get(actor, "core.player")

    if not player then
        error("player has no selected species")
    end

    return catalog.get("species", player.species_id)
end

-- Map the chosen stat ID to its stored field before modifying the attributes component.
local function increase_stat(attributes, id, amount)
    local field = stat_fields[id]

    if not field then
        error("unsupported level-up stat " .. tostring(id))
    end

    attributes[field] = attributes[field] + amount
end

-- Recompute derived HP and MP at each attained level before granting the species stat increase.
function advancement.apply_level(ctx, actor, level, species)
    local progress = ctx:get(actor, "core.progression")
    local attributes = ctx:get(actor, "core.attributes")
    local skills = ctx:get(actor, "core.skills")
    if not attributes or not skills then
        error("player lacks advancement components")
    end

    local drain = ctx:get(actor, component.PLAYER_DRAIN)
    local drain_loss = drain and drain.amount or 0
    mutation_transition.grant_scheduled(ctx, actor, species, level)

    local health = ctx:get(actor, "core.health")
    local magic = ctx:get(actor, "core.magic")
    local regeneration = ctx:get(actor, "core.regeneration")

    if not health or not magic or not regeneration or
        health.max <= 0 or magic.max < 0 then
        error("player lacks advancement resources")
    end

    local base_hp = math.max(1,
        formulas.max_hp(ctx, actor, level, species, skills.entries) - drain_loss)
    local next_hp = rage.scale_hp(ctx, actor,
        forms.scale_hp(ctx, actor, base_hp))
    local next_mp = formulas.max_mp(ctx, actor, level, species, skills.entries)
    local stat_frequency = species.levelup_stat_frequency
    local stat_options = type(species.levelup_stats) == "table" and species.levelup_stats or {}

    if stat_frequency > 0 and #stat_options > 0 and level % stat_frequency == 0 then
        local index = ctx:random("level", #stat_options) + 1
        increase_stat(attributes, stat_options[index], 1)
    end

    formulas.rescale_health(health, regeneration, next_hp)

    if magic.max > 0 then
        magic.current = math.floor(magic.current * next_mp / magic.max)
    else
        magic.current = next_mp
    end

    magic.max = next_mp
    progress.level = level
    extra_lives.on_level(ctx, actor, level)
    ctx:set(actor, "core.attributes", attributes)
    ctx:set(actor, "core.health", health)
    ctx:set(actor, "core.magic", magic)
    ctx:set(actor, "core.regeneration", regeneration)
    ctx:set(actor, "core.progression", progress)
    spell_records.grant_scheduled(ctx, actor, level)

    local message = "You have reached level " .. level .. "!"

    local maximum = experience_limit.max_level(ctx, actor)

    if level == 27 then
        message = "You have reached level 27, the final one!"
    elseif level == maximum then
        message = "You have reached level " .. level ..
            ", the highest you will ever reach!"
    end

    ctx:emit("level-up", message)
end

-- Stop at a pending manual stat choice so later levels cannot skip that input boundary.
function advancement.advance(ctx, actor)
    local progress = ctx:get(actor, "core.progression")

    if not progress or progress.level < 1 or progress.level > 27 then
        error("player has invalid advancement state")
    end

    if progress.pending_stat_level ~= 0 then
        return
    end

    local species = selected_species(ctx, actor)

    local maximum = experience_limit.max_level(ctx, actor)

    -- The current mutation-adjusted cap bounds this entire level-gain pass.
    while progress.level < maximum do
        local next_level = progress.level + 1
        local needed = experience_limit.needed(ctx, actor, next_level)

        if progress.total_xp < needed then
            break
        end

        if formulas.needs_manual_stat(ctx, actor, next_level) then
            progress.pending_stat_level = next_level
            ctx:set(actor, "core.progression", progress)
            ctx:emit("stat-choice", "Your experience leads to an increase in your attributes!")
            break
        end

        advancement.apply_level(ctx, actor, next_level, species)
        progress.level = next_level
    end

    extra_lives.on_experience(ctx, actor)
end

-- Ru's Inexperienced mutation raises every XP threshold immediately.
-- Match level_change's loss loop after the mutation, then recalculate
-- resources using the same owner that reacts to skill aptitude changes.
function advancement.reconcile_loss(ctx, actor)
    local progress = ctx:get(actor, component.PROGRESSION)
    local maximum = experience_limit.max_level(ctx, actor)
    local old_level = progress.level

    while progress.level > 1 and
        (progress.level > maximum or
            progress.total_xp < experience_limit.needed(
                ctx, actor, progress.level)) do
        progress.level = progress.level - 1
        ctx:emit("level-up",
            "You are now level " .. progress.level .. "!")
    end

    if progress.level == old_level then
        return false
    end

    if progress.pending_stat_level > progress.level then
        progress.pending_stat_level = 0
    end

    ctx:set(actor, component.PROGRESSION, progress)
    availability.reassess(ctx, actor)

    return true
end

-- Accept only the pending next-level choice, then write the selected base attribute.
function advancement.choose_stat(ctx, actor, id)
    local progress = ctx:get(actor, "core.progression")

    if not progress or progress.pending_stat_level ~= progress.level + 1 then
        error("no stat choice is pending")
    end

    local attributes = ctx:get(actor, "core.attributes")

    if not attributes then
        error("player has no attributes")
    end

    if not stat_fields[id] then
        return { message = "Choose Strength, Intelligence, or Dexterity." }
    end

    increase_stat(attributes, id,
        formulas.manual_stat_amount(ctx, actor))
    local next_level = progress.pending_stat_level
    progress.pending_stat_level = 0
    ctx:set(actor, "core.attributes", attributes)
    ctx:set(actor, "core.progression", progress)
    local species = selected_species(ctx, actor)
    advancement.apply_level(ctx, actor, next_level, species)
    advancement.advance(ctx, actor)

    return { chosen = true }
end

-- Bind the input command to the current player rather than trusting a caller-supplied actor.
function advancement.choose_stat_policy(ctx, input)
    return advancement.choose_stat(ctx, ctx:player(), input.stat)
end

register.policy({
    id = "character.choose_stat",
    run = advancement.choose_stat_policy,
})

return advancement
