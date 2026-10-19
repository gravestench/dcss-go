-- Player Irradiate delegates its burst to the shared actor-neutral rule.
-- This file owns player spell registration and the saved status timers.
local area = require("policy.combat.monster_area.irradiate")
local channels = require("constants.message_channels")
local component = require("constants.component")
local registry = require("policy.magic.effects.registry")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local zap_ids = require("policy.magic.effects.zaps.ids")

local irradiate = {}

-- The player cast announces itself before the shared burst. Only the
-- player version gains source self-contamination after its neighboring hits.
function irradiate.resolve(ctx, player, _, _, power)
    ctx:emit(channels.SPELL,
        "You erupt in a fountain of uncontrolled magic!")

    area.resolve(ctx, player, power, streams.SPELL)
end

-- Example: A Wretched monster loses its saved duration before choosing another action.
-- Expire the monster's Wretched duration before its next decision.
function irradiate.tick_wretched(ctx, entity)
    -- Wretched duration lives on the monster component so later turns can
    -- expire the effect after save and restore.
    local state = ctx:get(entity, zap_ids.component.WRETCHED)

    if not state then
        return
    end

    state.remaining_aut = state.remaining_aut - 10

    if state.remaining_aut <= 0 then
        ctx:remove(entity, zap_ids.component.WRETCHED)
    else
        ctx:set(entity, zap_ids.component.WRETCHED, state)
    end
end

-- Dissipate the saved player contamination by elapsed action time.
function irradiate.tick_contamination(ctx, entity, aut)
    if entity ~= ctx:player() then
        return
    end

    local state = ctx:get(entity, zap_ids.component.CONTAMINATION)

    if not state then
        return
    end

    -- timed-effects.cc:_apply_contam_over_time dissipates 75 per 10 aut.
    local scaled = 75 * aut
    local decrease = math.floor(scaled / 10)

    if ctx:random(streams.SPELL, 10) < scaled % 10 then
        decrease = decrease + 1
    end

    state.amount = math.max(0, state.amount - decrease)

    if state.amount == 0 then
        ctx:remove(entity, zap_ids.component.CONTAMINATION)
    else
        ctx:set(entity, zap_ids.component.CONTAMINATION, state)
    end
end

registry.add(spells.SPELL_IRRADIATE, {
    resolve = irradiate.resolve,
})

-- Theory of operation: Wretched monster timers expire before their decisions, so restored state has the same duration.
register.system({
    id = "zap.wretched.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = irradiate.tick_wretched,
})

-- Theory of operation: Player contamination dissipates after spell attacks and before movement using elapsed aut.
register.system({
    id = "zap.contamination.tick",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = irradiate.tick_contamination,
})

return irradiate
