-- Slimy-wall damage follows cloud exposure on each actor action. Two
-- registrations keep monster and player timing explicit in the scheduler.
local walls = require("policy.world.slime_walls")

local system = {}

-- Monster wall contact resolves before regeneration and AI read live HP.
function system.monster(ctx, actor, elapsed_aut)
    if actor ~= ctx:player() then
        walls.expose(ctx, actor, elapsed_aut)
    end
end

-- Player wall contact follows cloud contact and precedes the death pass.
function system.player(ctx, actor, elapsed_aut)
    if actor == ctx:player() then
        walls.expose(ctx, actor, elapsed_aut)
    end
end

register.system({
    id = "world.slime_wall.monster",
    scope = "active",
    query = {},
    after = { "world.cloud.monster_exposure" },
    before = { "monster.regeneration" },
    update = system.monster,
})

register.system({
    id = "world.slime_wall.player",
    scope = "active",
    query = {},
    after = { "world.cloud.player_exposure" },
    before = { "actor.death" },
    update = system.player,
})

return system
