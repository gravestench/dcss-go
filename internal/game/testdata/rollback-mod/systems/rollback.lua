-- The system throws after world movement so game state must roll back the partially applied turn.
-- Theory of operation: the active actor reaches this system only after
-- movement. It stages an HP edit, then deliberately fails. The game must
-- discard both this edit and the earlier movement before the next action.

register.system({
    id = "test.rollback",
    scope = "active",
    query = { "core.player", "core.health" },
    after = { "world.movement" },
    -- Use ctx:set to stage the edit as a normal ECS write. Throwing after it
    -- tests rollback of real queued commands, not merely Lua local state.
    update = function(ctx, actor)
        local health = ctx:get(actor, "core.health")
        health.current = health.current - 1
        ctx:set(actor, "core.health", health)

        error("intentional rollback")
    end,
})
