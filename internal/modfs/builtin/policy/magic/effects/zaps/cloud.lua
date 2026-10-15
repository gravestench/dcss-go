local component = require("constants.component")
local fire = require("policy.magic.effects.zaps.cloud_fire")
local cold = require("policy.magic.effects.zaps.cloud_cold")
local embers = require("policy.magic.effects.zaps.cloud_embers")
local mephitic = require("policy.magic.effects.zaps.cloud_mephitic")

local cloud = {}
local handlers = {
    CLOUD_FIRE = fire,
    CLOUD_COLD = cold,
    CLOUD_EMBERS = embers,
    CLOUD_MEPHITIC = mephitic,
}

function cloud.at(ctx, level_id, x, y)
    for _, entity in ipairs(ctx:query({ component.CLOUD })) do
        local state = ctx:get(entity, component.CLOUD)

        if state.level_id == level_id and state.x == x and state.y == y and
            state.expires_aut > ctx:aut() then
            return entity
        end
    end

    return nil
end

function cloud.place(ctx, kind_id, owner, level_id, x, y, duration)
    if not handlers[kind_id] then
        error("unknown cloud kind " .. tostring(kind_id))
    end

    if duration < 1 or not ctx:walkable(level_id, x, y) or
        cloud.at(ctx, level_id, x, y) then
        return nil
    end

    local entity = ctx:create()

    ctx:add(entity, component.CLOUD, {
        kind_id = kind_id,
        owner = owner,
        level_id = level_id,
        x = x,
        y = y,
        expires_aut = ctx:aut() + duration,
    })

    return entity
end

function cloud.tick(ctx, actor)
    local position = ctx:get(actor, component.POSITION)
    local health = ctx:get(actor, component.HEALTH)

    for _, entity in ipairs(ctx:query({ component.CLOUD })) do
        local state = ctx:get(entity, component.CLOUD)

        if ctx:aut() >= state.expires_aut then
            local handler = handlers[state.kind_id]

            if handler and handler.expire then
                handler.expire(ctx, entity, state)
            else
                ctx:destroy(entity)
            end
        elseif position and health and health.current > 0 and
            position.level_id == state.level_id and
            position.x == state.x and position.y == state.y then
            local handler = handlers[state.kind_id]

            if not handler then
                error("saved cloud has unknown kind " .. state.kind_id)
            end

            handler.apply(ctx, actor, state)
        end
    end
end

function cloud.update(ctx, actor)
    cloud.tick(ctx, actor)
end

register.system({
    id = "magic.cloud.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = cloud.update,
})

return cloud
