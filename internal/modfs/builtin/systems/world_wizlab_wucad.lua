-- Wucad's saved timer and numbered message cells advance only while
-- the player acts on this lab floor. Monster death is handled by the
-- policy's generic death hook after the regular combat pipeline.
local component = require("constants.component")
local events = require("policy.world.wizlab.events.wucad")
local intents = require("constants.intent")

local system = {}

-- Persist only a changed event state; other Wizard Labs are untouched.
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
        component.WORLD_WIZLAB_WUCAD,
    })) do
        local state = ctx:get(entity,
            component.WORLD_WIZLAB_WUCAD)

        if events.tick(ctx, state, position, delta,
            intent and intent.kind == intents.MOVE) then
            ctx:set(entity, component.WORLD_WIZLAB_WUCAD,
                state)
        end
    end
end

register.system({
    id = "world.wizlab_wucad",
    scope = "active",
    query = {},
    after = { "world.wizlab_portals", "world.movement" },
    before = { "actor.death" },
    update = system.update,
})

return system
