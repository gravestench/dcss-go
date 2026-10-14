register.system({
    id = "test.host_bridge",
    query = { "core.health" },
    update = function(ctx, entity)
        local health = ctx:get(entity, "core.health")
        health.current = health.current + 1
        ctx:set(entity, "core.health", health)
    end,
})
