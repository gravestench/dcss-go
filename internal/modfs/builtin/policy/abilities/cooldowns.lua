local component = require("constants.component")
local intent_ids = require("constants.intent")
local guardian = require("policy.mutations.effects.damage.demonic_guardian")

local cooldowns = {}

function cooldowns.tick(ctx, player, aut)
    if aut <= 0 then
        return
    end

    guardian.tick(ctx, player, aut)

    local breath = ctx:get(player, component.BREATH_COOLDOWN)

    if breath then
        breath.remaining_aut = math.max(0,
            breath.remaining_aut - aut)
        ctx:set(player, component.BREATH_COOLDOWN, breath)
    end

    local state = ctx:get(player, component.ABILITY_COOLDOWNS)

    if not state then
        return
    end

    local intent = ctx:get(player, component.INTENT)
    local walking = intent and intent.kind == intent_ids.MOVE

    -- Source: movement.cc postpones DUR_NO_HOP recovery while walking.
    if not walking then
        state.hop_aut = math.max(0, state.hop_aut - aut)
    end

    state.word_of_chaos_aut = math.max(0,
        state.word_of_chaos_aut - aut)
    ctx:set(player, component.ABILITY_COOLDOWNS, state)
end

return cooldowns
