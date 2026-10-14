register.policy({
    id = "test.invalid_output",
    run = function(ctx)
        ctx:create()

        return 4
    end,
})

register.policy({
    id = "test.apply_failure",
    run = function(ctx, input)
        local player = ctx:player()
        local health = ctx:get(player, "core.health")
        health.current = health.current - 1
        ctx:set(player, "core.health", health)
        ctx:set_cell(input.level_id, input.x, input.y, "#")

        return {}
    end,
})
