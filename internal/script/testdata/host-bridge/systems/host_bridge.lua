-- Host Bridge verifies a Lua system can call a provided host capability.
-- Theory of operation: query a host-owned health component and write its
-- increment through the Lua context bridge on each matching entity.

register.system({
    id = "test.host_bridge",
    query = { "core.health" },
    -- Read and set the same host component so the bridge must translate both
    -- directions of the component value without losing its schema.
    update = function(ctx, entity)
        local health = ctx:get(entity, "core.health")
        health.current = health.current + 1
        ctx:set(entity, "core.health", health)
    end,
})
