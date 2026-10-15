local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local choice = require("policy.character_choice")
local spell_records = require("policy.character.spell_records")
local forms = require("policy.magic.effects.forms.player")

local function valid_stat_gains(deltas, manual_choices, species_gains, allowed_stats)
    local allowed = {}

    for _, stat in ipairs(allowed_stats or {}) do
        allowed[stat] = true
    end

    for strength = 0, manual_choices do
        for intelligence = 0, manual_choices - strength do
            local dexterity = manual_choices - strength - intelligence
            local remaining = {
                str = deltas.str - 2 * strength,
                int = deltas.int - 2 * intelligence,
                dex = deltas.dex - 2 * dexterity,
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
    local origin = ctx:get(entity, "character.origin")

    if not origin then
        error("player lacks character origin")
    end

    if progress.level < 1 or progress.level > 27 then
        error("invalid player level " .. progress.level)
    end

    if progress.total_xp < formulas.experience_needed(progress.level, species.xp) then
        error("player XL" .. progress.level .. " lacks experience")
    end

    local earned = formulas.level_for_experience(progress.total_xp, species.xp)
    local pending = progress.pending_stat_level

    if pending == 0 then
        if progress.level ~= earned then
            error("player level " .. progress.level .. " disagrees with experience")
        end
    elseif pending ~= progress.level + 1 or not formulas.needs_manual_stat(pending) or
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

    for level = 2, progress.level do
        if formulas.needs_manual_stat(level) then
            manual_gains = manual_gains + 1
        end

        if species.levelup_stat_frequency > 0 and #species.levelup_stats > 0 and
            level % species.levelup_stat_frequency == 0 then
            random_gains = random_gains + 1
        end
    end

    local deltas = {
        str = attributes.strength - base.strength,
        int = attributes.intelligence - base.intelligence,
        dex = attributes.dexterity - base.dexterity,
    }

    if not valid_stat_gains(deltas, manual_gains, random_gains, species.levelup_stats) then
        error("invalid player attribute gains for entity " .. ctx:id(entity))
    end

    if health.max ~= forms.max_hp(ctx, entity) then
        error("invalid player max HP for entity " .. ctx:id(entity))
    end

    local max_mp = formulas.max_mp(progress.level, species, skills.entries)

    if magic.max ~= max_mp or magic.current < 0 or magic.current > max_mp then
        error("invalid player MP for entity " .. ctx:id(entity))
    end

    local status = ctx:get(entity, "magic.player_status")

    if status and (status.blink_cooldown_aut < 0 or
        status.disjunction_aut < 0 or status.vertigo_aut < 0) then
        error("invalid player spell status duration")
    end

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

    spell_records.validate(ctx, entity)
end

local module = {}

function module.run(ctx)
    validate(ctx)
    return {}
end

register.policy({
    id = "save.validate_player",
    run = module.run,
})

return module
