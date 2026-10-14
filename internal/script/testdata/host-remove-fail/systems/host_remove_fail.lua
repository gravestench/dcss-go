register.system({
    id = "test.host_remove_fail",
    query = { "core.health" },
    update = function(ctx, entity)
        ctx:remove(entity, "core.health")
        error("intentional failure after host removal")
    end,
})
