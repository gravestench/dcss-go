local effects = require("policy.magic.effects.registry")
local resources = require("policy.magic.resources")
local statuses = require("policy.magic.effects.statuses.player")
local confusion = require("policy.magic.player_confusion")

local channel = {}

-- Replace an existing channel state so a new cast cannot retain the previous spell's stage.
function channel.begin(ctx, player, state)
    if ctx:has(player, "magic.channel") then
        ctx:set(player, "magic.channel", state)
    else
        ctx:add(player, "magic.channel", state)
    end
end

-- Example: cancelling Searing Ray removes its saved continuation before the next wait action.
-- Remove saved continuation state so later waits cannot resume an interrupted spell.
function channel.cancel(ctx, player)
    if ctx:has(player, "magic.channel") then
        ctx:remove(player, "magic.channel")
    end
end

-- The initial cast runs before this call. The saved stage then describes the
-- next wait continuation, as in spl-damage.cc's _do_wait_spells flow.
function channel.cast_finished(ctx, player)
    local state = ctx:get(player, "magic.channel")

    if not state then
        return
    end

    state.stage = state.stage + 1
    ctx:set(player, "magic.channel", state)
end

-- Recheck interruption conditions at each wait; charge MP only when a continuation fires.
function channel.wait(ctx, player, aut)
    local state = ctx:get(player, "magic.channel")

    if not state then
        return
    end

    local effect = effects.get(state.spell_id)
    local continuation_mp = effect and effect.continuation_mp or 1

    if not effect or not effect.continue or
        confusion.active(ctx, player) or
        statuses.silence_radius(ctx, player) >= 0 or
        resources.cannot_pay(ctx, player, continuation_mp) then
        channel.cancel(ctx, player)

        return
    end

    -- A friendly-fire tracer can cancel before the extra MP is spent.
    local fired, keep = effect.continue(ctx, player, state, aut)

    if fired and continuation_mp > 0 then
        resources.pay(ctx, player, continuation_mp)
    end

    if not fired or not keep then
        channel.cancel(ctx, player)

        return
    end

    state.stage = state.stage + 1
    ctx:set(player, "magic.channel", state)
end

-- Let a channel effect discount its own continuation while bounding the returned cost to a legal cast.
function channel.cost(ctx, player, normal_cost)
    local state = ctx:get(player, "magic.channel")

    if not state then
        return normal_cost
    end

    local effect = effects.get(state.spell_id)

    if not effect or not effect.continuation_cost then
        return normal_cost
    end

    local cost = effect.continuation_cost(ctx, player, state, normal_cost)

    if type(cost) ~= "number" or cost % 1 ~= 0 or
        cost < 1 or cost > normal_cost then
        error("invalid channel continuation cost for " .. state.spell_id)
    end

    return cost
end

return channel
