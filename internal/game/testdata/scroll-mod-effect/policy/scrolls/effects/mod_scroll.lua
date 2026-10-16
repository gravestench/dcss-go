local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")

local effect = {}

function effect.prepare()
    return nil
end

function effect.apply(ctx, player)
    local health = ctx:get(player, "core.health")

    health.current = math.min(health.max, health.current + 1)
    ctx:set(player, "core.health", health)
end

scrolls.register(item_ids.SCR_MOD_TEST, effect)

return effect
