register.system({
    id = "test.host_invalid",
    query = { "core.health" },
    update = function(ctx, entity)
        ctx:set(entity, "core.health", {
            current = "not an integer",
        })
    end,
})
