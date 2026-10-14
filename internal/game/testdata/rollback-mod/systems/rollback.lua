register.system({
    id = "test.rollback",
    scope = "active",
    query = { "core.player", "core.health" },
    after = { "world.movement" },
    update = function(ctx, actor)
        local health = ctx:get(actor, "core.health")
        health.current = health.current - 1
        ctx:set(actor, "core.health", health)

        error("intentional rollback")
    end,
})
