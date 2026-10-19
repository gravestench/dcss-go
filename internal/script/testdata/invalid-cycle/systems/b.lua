-- System B depends on A, closing the scheduling cycle.
-- Theory of operation: B declares the reverse after edge to A; together the
-- two fixtures form a cycle that the scheduler must diagnose at load time.

register.system{
    id = "test.b",
    after = { "test.a" },
    -- An empty body keeps this fixture about dependency validation alone;
    -- the scheduler should reject it before any update executes.
    update = function() end,
}
