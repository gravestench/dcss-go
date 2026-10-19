-- Invalid output and apply failure policies probe transaction rollback after a Lua policy runs.

local terrain = require("constants.terrain")

register.policy({
    id = "test.invalid_output",
    -- Stage a created entity, then violate the policy return contract.
    -- The caller must discard that entity instead of committing half a turn.
    -- Example: runtime.Policy("test.invalid_output", nil) must return an error.
    run = function(ctx)
        ctx:create()

        return 4
    end,
})

register.policy({
    id = "test.apply_failure",
    -- Queue health and terrain changes together. If the terrain operation
    -- fails at commit, both changes must roll back as one transaction.
    -- Example: runtime.Policy("test.apply_failure", cell_input).
    run = function(ctx, input)
        local player = ctx:player()
        local health = ctx:get(player, "core.health")
        health.current = health.current - 1
        ctx:set(player, "core.health", health)
        ctx:set_cell(input.level_id, input.x, input.y, terrain.DNGN_ROCK_WALL)

        return {}
    end,
})
