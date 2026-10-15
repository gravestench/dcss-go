local component = require("constants.component")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

local sanguine = {}

local MIN_DURATION_AUT = 60
local DURATION_SPREAD_AUT = 41

function sanguine.active(ctx, player)
    local state = ctx:get(player, component.SANGUINE_ARMOUR)

    return state and state.remaining_aut > 0 or false
end

function sanguine.valid(ctx, player)
    local health = ctx:get(player, component.HEALTH)

    return health and health.current > 0 and
        health.current * 3 <= health.max * 2 and
        mutation_levels.full(ctx, player,
            mutations.MUT_SANGUINE_ARMOUR) > 0 or false
end

local function refresh(ctx, player, state)
    if state.remaining_aut == 0 then
        ctx:emit("duration", "Your blood congeals into armour.")
    end

    state.remaining_aut = MIN_DURATION_AUT +
        ctx:random("mutation", DURATION_SPREAD_AUT)
    ctx:set(player, component.SANGUINE_ARMOUR, state)
end

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
