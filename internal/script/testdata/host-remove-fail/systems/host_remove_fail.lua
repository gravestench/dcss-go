-- An error after host removal tests rollback of the removed entity.
-- Theory of operation: remove a host-owned component, then fail the Lua
-- system; rollback must restore the component after the failed turn.

register.system({
    id = "test.host_remove_fail",
    query = { "core.health" },
    -- Make removal observable before raising the intentional error, so the
    -- transaction test checks restoration rather than a no-op failure.
    update = function(ctx, entity)
        ctx:remove(entity, "core.health")
        error("intentional failure after host removal")
    end,
})
