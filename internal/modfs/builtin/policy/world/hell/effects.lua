-- Theory of operation: every arrival on a Hell subbranch floor may punish
-- the player. The source first asks Zin for protection, then draws one
-- message and one of four equal consequences. All lasting changes go to
-- their existing ECS owners, so a failed stair transaction rolls them back.
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local classes = require("constants.mutation_classes")
local component = require("constants.component")
local gods = require("constants.gods")
local kinds = require("constants.hell_effects")
local mutation_choices = require("constants.mutation_choices")
local stats = require("constants.stats")
local streams = require("constants.rng_streams")
local undead = require("constants.undead_states")
local forms = require("constants.form_ids")
local catalog = require("policy.catalog")
local drain = require("policy.combat.player_drain")
local messages = require("data.hell_effect_messages")
local noise = require("policy.world.noise")
local silence = require("policy.world.silence")
local stat_loss = require("policy.character.stat_loss")
local transition = require("policy.mutations.transition")
local vampire = require("policy.character.vampire")

local effects = {}

-- The source smell check excludes lifeless undead, including an unalive
-- Vampire and a temporarily undead Lich Form. Nonliving species still smell.
local function can_smell(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get(categories.SPECIES, identity.species_id)
    local form = ctx:get(player, component.PLAYER_FORM)

    if form and form.form_id == forms.LICH then
        return false
    end

    if species.undead_type == undead.SEMI_UNDEAD then
        return vampire.alive(ctx, player)
    end

    return species.undead_type ~= undead.UNDEAD
end

-- Keep these draws in source order. A protected arrival consumes only the
-- protection roll; Silence suppresses noise but not the one-in-six draw.
-- The fourth consequence intentionally has no effect beyond its message.
function effects.plan(ctx, worship, silenced, smells)
    if worship.god_id == gods.ZIN and
        ctx:random(streams.HELL_EFFECT, kinds.MAX_PIETY * 2) <
            worship.piety then
        return {
            protected = true,
        }
    end

    local loud = ctx:random(streams.HELL_EFFECT,
        kinds.LOUD_CHANCE) == 0 and not silenced
    local group = loud and messages.noisy or messages.quiet
    local selected = group[ctx:random(streams.HELL_EFFECT, #group) + 1]

    if selected == messages.quiet[1] and smells == false then
        selected = messages.no_smell
    end

    local outcome = kinds.OUTCOMES[ctx:random(streams.HELL_EFFECT,
        #kinds.OUTCOMES) + 1]

    return {
        protected = false,
        loud = loud,
        message = selected,
        outcome = outcome,
    }
end

-- Existing mutation, drain, and stat owners retain their ordinary recovery
-- rules. Stat loss rolls its die before choosing a stat, as the source call
-- evaluates its amount argument before STAT_RANDOM inside lose_stat.
local function consequence(ctx, player, outcome)
    if outcome == kinds.BAD_MUTATION then
        transition.grant_random(ctx, player, mutation_choices.BAD,
            classes.TEMPORARY, false)
    elseif outcome == kinds.DRAIN then
        drain.apply(ctx, player, kinds.DRAIN_POWER,
            streams.HELL_EFFECT)
    elseif outcome == kinds.STAT_LOSS then
        local amount = ctx:random(streams.HELL_EFFECT,
            kinds.STAT_DIE) + 1
        local index = ctx:random(streams.HELL_EFFECT,
            #stats.ORDER) + 1

        local field = stats.ORDER[index]

        stat_loss.drain(ctx, player, field, amount)
        ctx:emit(channels.COMBAT, messages.stat_loss[field])
    end
end

-- Call only after the travel kernel has placed the player on a Hell floor.
-- The loud version wakes nearby actors through the normal sound service.
function effects.arrive(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local position = ctx:get(player, component.POSITION)

    if not worship or not position then
        error("Hell arrival requires player worship and position")
    end

    local silenced = silence.at(ctx, position.level_id,
        position.x, position.y)
    local plan = effects.plan(ctx, worship, silenced,
        can_smell(ctx, player))

    if plan.protected then
        ctx:emit(channels.HELL_EFFECT,
            "Zin's power protects you from the chaos of Hell!")

        return plan
    end

    ctx:emit(channels.HELL_EFFECT, plan.message)

    if plan.loud then
        noise.emit(ctx, position, kinds.LOUD_VOLUME, player)
    end

    consequence(ctx, player, plan.outcome)

    return plan
end

return effects
