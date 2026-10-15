local statuses = require("policy.magic.effects.statuses.player")

local health_policy = {}

-- All ordinary damage to the player passes through this rule. The source's
-- ouch.cc exception is reserved for explicitly fatal environmental causes.
function health_policy.damage(ctx, player, amount, fatal_exception, attacker)
    local health = ctx:get(player, "core.health")

    if not health then
        error("player has no health")
    end

    local dealt = statuses.death_door_damage(ctx, player, amount,
        fatal_exception or false)

    health.current = math.max(0, health.current - dealt)
    ctx:set(player, "core.health", health)

    if attacker and attacker ~= player and dealt > 0 then
        statuses.anguish_reflect(ctx, attacker, dealt)
    end

    return health, dealt
end

function health_policy.can_heal(ctx, player)
    return not statuses.death_door_active(ctx, player)
end

return health_policy
