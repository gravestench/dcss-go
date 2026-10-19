-- The overlaid scroll heals exactly one HP through the registered scroll effect.

local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")

local effect = {}

-- No target or option is needed for this healing scroll, so preparation
-- returns nil and the shared scroll flow can proceed directly to apply.
-- Example: effect.prepare() before effect.apply(ctx, player).
function effect.prepare()
    return nil
end

-- Clamp healing at max HP and write the component back through ECS; editing
-- only the fetched Lua table would not persist the result.
function effect.apply(ctx, player)
    local health = ctx:get(player, "core.health")

    health.current = math.min(health.max, health.current + 1)
    ctx:set(player, "core.health", health)
end

scrolls.register(item_ids.SCR_MOD_TEST, effect)

return effect
