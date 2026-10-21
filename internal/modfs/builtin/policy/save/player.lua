local catalog = require("policy.catalog")
local component = require("constants.component")
local formulas = require("policy.character.formulas")
local experience_limit = require("policy.character.experience_limit")
local extra_lives = require("policy.character.extra_lives")
local choice = require("policy.character_choice")
local spell_records = require("policy.character.spell_records")
local mutation_records = require("policy.mutations.records")
local evolution = require("policy.mutations.evolution")
local forms = require("policy.magic.effects.forms.player")
local rage = require("policy.character.rage")
local gods = require("constants.gods")
local religion_validation = require("policy.religion.validation")
local mutation_effects = require("policy.mutations.effects.registry")
local mutation_capabilities = require("constants.mutation_capabilities")
local vampire = require("policy.character.vampire")
local identification = require("policy.items.identification")

-- Enumerating legal manual choices prevents a forged stat total from passing save validation.
local function valid_stat_gains(deltas, manual_choices, manual_amount,
    species_gains, allowed_stats)
    local allowed = {}

    for _, stat in ipairs(allowed_stats or {}) do
        allowed[stat] = true
    end

    for strength = 0, manual_choices do
        for intelligence = 0, manual_choices - strength do
            local dexterity = manual_choices - strength - intelligence
            local remaining = {
                str = deltas.str - manual_amount * strength,
                int = deltas.int - manual_amount * intelligence,
                dex = deltas.dex - manual_amount * dexterity,
            }

            if remaining.str >= 0 and remaining.int >= 0 and remaining.dex >= 0 and
                remaining.str + remaining.int + remaining.dex == species_gains and
                (allowed.str or remaining.str == 0) and
                (allowed.int or remaining.int == 0) and
                (allowed.dex or remaining.dex == 0) then
                return true
            end
        end
    end

    return false
end

-- Reconstruct legal species and job-derived state before accepting saved player fields.
local function validate(ctx)
    local entity = ctx:player()
    local player = ctx:get(entity, "core.player")
    local actor = ctx:get(entity, "core.actor")
    local attributes = ctx:get(entity, "core.attributes")
    local skills = ctx:get(entity, "core.skills")
    local progress = ctx:get(entity, "core.progression")
    local health = ctx:get(entity, "core.health")
    local magic = ctx:get(entity, "core.magic")

    if not player or not actor or not attributes or not skills or
        not progress or not health or not magic then
        error("invalid player entity " .. ctx:id(entity))
    end

    local species = catalog.get("species", player.species_id)
    local job = catalog.get("jobs", player.job_id)

    if not choice.allowed(species, job) then
        error("invalid player choice")
    end
    local origin = ctx:get(entity, component.CHARACTER_ORIGIN)

    if not origin then
        error("player lacks character origin")
    end

    local historical_level = extra_lives.validate(ctx, entity,
        progress, health)

    local maximum = experience_limit.max_level(ctx, entity)

    if progress.level < 1 or progress.level > maximum then
        error("invalid player level " .. progress.level)
    end

    if progress.total_xp < formulas.experience_needed(progress.level, species.xp) then
        error("player XL" .. progress.level .. " lacks experience")
    end

    local earned = formulas.level_for_experience(progress.total_xp,
        species.xp, maximum)
    local pending = progress.pending_stat_level

    -- A pending manual stat choice is the only accepted gap between earned XL and committed XL.
    if pending == 0 then
        if progress.level ~= earned then
            error("player level " .. progress.level .. " disagrees with experience")
        end
    elseif pending ~= progress.level + 1 or pending > maximum or
        not formulas.needs_manual_stat(ctx, entity, pending) or
        progress.total_xp < formulas.experience_needed(pending, species.xp) then
        error("invalid pending player stat choice at XL" .. pending)
    end

    local base = {
        strength = species.strength + job.strength + origin.strength_bonus,
        intelligence = species.intelligence + job.intelligence + origin.intelligence_bonus,
        dexterity = species.dexterity + job.dexterity + origin.dexterity_bonus,
    }

    if attributes.strength < base.strength or attributes.intelligence < base.intelligence or
        attributes.dexterity < base.dexterity then
        error("invalid player attributes for entity " .. ctx:id(entity))
    end

    local manual_gains = 0
    local random_gains = 0
    local levelup_stats = type(species.levelup_stats) == "table" and
        species.levelup_stats or {}

    for level = 2, historical_level do
        if formulas.needs_manual_stat(ctx, entity, level) then
            manual_gains = manual_gains + 1
        end

        if species.levelup_stat_frequency > 0 and #levelup_stats > 0 and
            level % species.levelup_stat_frequency == 0 then
            random_gains = random_gains + 1
        end
    end

    local deltas = {
        str = attributes.strength - base.strength,
        int = attributes.intelligence - base.intelligence,
        dex = attributes.dexterity - base.dexterity,
    }

    local manual_amount = formulas.manual_stat_amount(ctx, entity)

    if not valid_stat_gains(deltas, manual_gains, manual_amount,
        random_gains, levelup_stats) then
        error("invalid player attribute gains for entity " .. ctx:id(entity))
    end

    local expected_hp = rage.scale_hp(ctx, entity,
        forms.max_hp(ctx, entity))

    if health.max ~= expected_hp then
        error("invalid player max HP for entity " .. ctx:id(entity) ..
            ": got " .. health.max .. ", want " .. expected_hp)
    end

    local max_mp = formulas.max_mp(ctx, entity, progress.level, species, skills.entries)

    if magic.max ~= max_mp or magic.current < 0 or magic.current > max_mp then
        error("invalid player MP for entity " .. ctx:id(entity))
    end

    local status = ctx:get(entity, "magic.player_status")

    local ability_cooldowns = ctx:get(entity,
        component.ABILITY_COOLDOWNS)

    if ability_cooldowns and
        (ability_cooldowns.hop_aut < 0 or
            ability_cooldowns.word_of_chaos_aut < 0) then
        error("invalid player ability cooldown")
    end

    local breath = ctx:get(entity, component.BREATH_COOLDOWN)

    if breath and breath.remaining_aut < 0 then
        error("invalid player breath cooldown")
    end

    local guardian = ctx:get(entity, component.DEMONIC_GUARDIAN)

    if guardian and guardian.cooldown_aut < 0 then
        error("invalid demonic guardian cooldown")
    end

    if status and (status.blink_cooldown_aut < 0 or
        status.lowered_will_aut < 0 or
        status.disjunction_aut < 0 or status.vertigo_aut < 0) then
        error("invalid player spell status duration")
    end

    require("policy.magic.player_teleport").validate(ctx, entity)

    local permanent_loss = ctx:get(entity, "magic.permanent_hp_loss")

    if permanent_loss and permanent_loss.amount < 0 then
        error("invalid permanent HP loss")
    end

    local paralysis = ctx:get(entity, "magic.player_paralysis")

    if paralysis and paralysis.remaining_aut <= 0 then
        error("invalid player paralysis duration")
    end

    local confusion = ctx:get(entity, "zap.player_confusion")

    if confusion and confusion.remaining_aut <= 0 then
        error("invalid player confusion duration")
    end

    local channel = ctx:get(entity, "magic.channel")

    if channel and (channel.spell_id == "" or channel.power < 0 or
        channel.stage < 1) then
        error("invalid player spell channel")
    end

    mutation_records.validate(ctx, entity, species, historical_level)
    vampire.validate(ctx, entity)

    local worship = religion_validation.check(ctx, entity)

    if worship.god_id ~= gods.NO_GOD and
        mutation_effects.sum(ctx, entity,
            mutation_capabilities.WORSHIP_FORBIDDEN) > 0 then
        error("Forlorn player cannot worship a god")
    end

    evolution.validate(ctx, entity)
    spell_records.validate(ctx, entity)
    identification.validate(ctx, entity)
end

local module = {}

-- Stat-gain validation reconstructs legal choices from species gains and manual choices.
-- Example: module.run(ctx) rejects stat gains that cannot arise from legal choices.
function module.run(ctx)
    validate(ctx)
    return {}
end

register.policy({
    id = "save.validate_player",
    run = module.run,
})

return module
