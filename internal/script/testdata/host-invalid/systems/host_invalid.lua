-- This system writes a string into an integer health field to test host-side component validation.
-- Theory of operation: issue a Lua update with the wrong field type and let
-- the host's registered component schema reject it at the boundary.

register.system({
    id = "test.host_invalid",
    query = { "core.health" },
    -- Supply a string where health requires an integer; the fixture checks
    -- validation rather than a particular combat result.
    update = function(ctx, entity)
        ctx:set(entity, "core.health", {
            current = "not an integer",
        })
    end,
})
