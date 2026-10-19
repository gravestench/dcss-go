-- The system raises an intentional error after mutation to test atomic rollback.
-- Theory of operation: write a component, then fail the update. The host
-- transaction must discard the write along with the failed Lua turn.

register.system{
    id = "test.fail",
    -- Fail only after a visible state change, so rollback cannot pass by
    -- skipping a system that had no effect.
    update = function(ctx, entity)
        ctx:add(entity, "test.counter", { value = 1 })
        error("intentional failure")
    end,
}
