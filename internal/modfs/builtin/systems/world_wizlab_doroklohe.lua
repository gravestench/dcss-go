-- This system advances only Doroklohe's saved clock. The event policy
-- handles its three source phases; other Wizard Labs register their own
-- small systems instead of extending a room-name switch.
local component = require("constants.component")
local events = require("policy.world.wizlab.events.doroklohe")

local system = {}

-- The scheduler supplies action start plus cost. Advance once for the
-- player action, then persist the phase before any later death effect.
function system.update(ctx, actor, delta)
    if actor ~= ctx:player() then
        return
    end

    local position = ctx:get(actor, component.POSITION)

    if not position then
        return
    end

    for _, entity in ipairs(ctx:query({
        component.WORLD_WIZLAB_DOROKLOHE,
    })) do
        local state = ctx:get(entity,
            component.WORLD_WIZLAB_DOROKLOHE)

        if events.tick(ctx, state, position, delta) then
            ctx:set(entity,
                component.WORLD_WIZLAB_DOROKLOHE, state)
        end
    end
end

register.system({
    id = "world.wizlab_doroklohe",
    scope = "active",
    query = {},
    after = { "world.wizlab_portals" },
    before = { "actor.death" },
    update = system.update,
})

return system
