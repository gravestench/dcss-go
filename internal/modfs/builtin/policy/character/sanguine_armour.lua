-- Example: A wounded player gains Sanguine Armour only while its recovery timer is live.
local component = require("constants.component")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

local sanguine = {}

local MIN_DURATION_AUT = 60
local DURATION_SPREAD_AUT = 41

-- AC consumers require a live timer rather than a low-HP condition alone.
function sanguine.active(ctx, player)
    local state = ctx:get(player, component.SANGUINE_ARMOUR)

    return state and state.remaining_aut > 0 or false
end

-- A living player below the HP threshold can sustain the blood armour reaction.
function sanguine.valid(ctx, player)
    local health = ctx:get(player, component.HEALTH)

    return health and health.current > 0 and
        health.current * 3 <= health.max * 2 and
        mutation_levels.full(ctx, player,
            mutations.MUT_SANGUINE_ARMOUR) > 0 or false
end

-- Emit the activation message only on transition from inactive to active.
local function refresh(ctx, player, state)
    if state.remaining_aut == 0 then
        ctx:emit("duration", "Your blood congeals into armour.")
    end

    state.remaining_aut = MIN_DURATION_AUT +
        ctx:random("mutation", DURATION_SPREAD_AUT)
    ctx:set(player, component.SANGUINE_ARMOUR, state)
end

-- A qualifying hit refreshes the armour timer; the first hit also creates the status component.
function sanguine.on_damage(ctx, player, dealt)
    if dealt <= 0 or not sanguine.valid(ctx, player) then
        return
    end

    local state = ctx:get(player, component.SANGUINE_ARMOUR)

    if state then
        refresh(ctx, player, state)
    else
        ctx:add(player, component.SANGUINE_ARMOUR, {
            remaining_aut = MIN_DURATION_AUT +
                ctx:random("mutation", DURATION_SPREAD_AUT),
        })
        ctx:emit("duration", "Your blood congeals into armour.")
    end
end

-- Regeneration of the armour follows elapsed aut, while invalid HP state ends its protection.
function sanguine.tick(ctx, player, aut)
    if aut <= 0 then
        return
    end

    local state = ctx:get(player, component.SANGUINE_ARMOUR)

    if not state then
        return
    end

    local before = state.remaining_aut

    state.remaining_aut = math.max(0, before - aut)

    if sanguine.valid(ctx, player) then
        refresh(ctx, player, state)
        return
    end

    if state.remaining_aut > 0 then
        state.remaining_aut = 1
    elseif before > 0 then
        ctx:emit("duration", "Your blood armour dries and flakes away.")
    end

    ctx:set(player, component.SANGUINE_ARMOUR, state)
end

return sanguine
