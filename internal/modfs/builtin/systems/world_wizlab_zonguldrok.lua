-- This focused system advances Zonguldrok's saved grave clock and the
-- one-shot L movement trigger. Its death hook is registered on load.
local component = require("constants.component")
local events = require("policy.world.wizlab.events.zonguldrok")
local intents = require("constants.intent")

local system = {}

-- The policy owns every source rule; the system only locates its Akara
-- state and persists changes after each player action.
function system.update(ctx, actor, delta)
    if actor ~= ctx:player() then
        return
    end

    local position = ctx:get(actor, component.POSITION)
    local intent = ctx:get(actor, component.INTENT)

    if not position then
        return
    end

    for _, entity in ipairs(ctx:query({
        component.WORLD_WIZLAB_ZONGULDROK,
    })) do
        local state = ctx:get(entity,
            component.WORLD_WIZLAB_ZONGULDROK)

        if events.tick(ctx, state, position, delta,
            intent and intent.kind == intents.MOVE) then
            ctx:set(entity,
                component.WORLD_WIZLAB_ZONGULDROK,
                state)
        end
    end
end

register.system({
    id = "world.wizlab_zonguldrok",
    scope = "active",
    query = {},
    after = { "world.wizlab_portals", "world.movement" },
    before = { "actor.death" },
    update = system.update,
})

return system
