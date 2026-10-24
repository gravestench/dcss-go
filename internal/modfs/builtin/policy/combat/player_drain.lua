local component = require("constants.component")
local roll = require("policy.combat.roll")

local drain = {}

-- Example: drain.apply(ctx, player, power, stream) with live player -> temporary max-HP drain component
-- ouch.cc: permanent max HP is untouched; XP can later recover
-- this temporary loss through the saved status.drain component.
function drain.apply(ctx, player, power, stream)
    local health = ctx:get(player, "core.health")
    local previous = ctx:get(player, component.PLAYER_DRAIN)

    if not health then
        error("drained player has no health")
    end

    local state = previous or { amount = 0 }
    local real_max = health.max + state.amount
    local loss = 1 + roll.random_divide(ctx, power * real_max, 750,
        stream)

    loss = math.min(loss, health.max - 1)

    if loss <= 0 then
        return health
    end

    state.amount = state.amount + loss
    health.max = health.max - loss
    health.current = math.min(health.current, health.max)

    ctx:set(player, "core.health", health)

    if previous then
        ctx:set(player, component.PLAYER_DRAIN, state)
    else
        ctx:add(player, component.PLAYER_DRAIN, state)
    end

    ctx:emit("combat", "You feel drained.")

    return health
end

return drain
