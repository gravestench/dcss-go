local component = require("constants.component")
local placement = require("policy.clouds.placement")
local exposure = require("policy.clouds.exposure")

local monster = {}
local player = {}

local function apply_at_actor(ctx, actor, elapsed_aut)
    local position = ctx:get(actor, component.POSITION)
    local health = ctx:get(actor, component.HEALTH)

    if not position or not health or health.current <= 0 then
        return
    end

    local cloud_entity, state = placement.at(ctx,
        position.level_id, position.x, position.y)

    if cloud_entity then
        exposure.apply(ctx, actor, cloud_entity, state, elapsed_aut)
    end
end

function monster.update(ctx, actor, elapsed_aut)
    if actor == ctx:player() then
        return
    end

    apply_at_actor(ctx, actor, elapsed_aut)
end

function player.update(ctx, actor, elapsed_aut)
    if actor ~= ctx:player() then
        return
    end

    apply_at_actor(ctx, actor, elapsed_aut)
end

register.system({
    id = "world.cloud.monster_exposure",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = monster.update,
})

register.system({
    id = "world.cloud.player_exposure",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = player.update,
})

return {
    monster = monster,
    player = player,
}
