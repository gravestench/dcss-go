-- System A depends on B, starting a dependency cycle that scheduling must reject.
-- Theory of operation: A declares an after edge to B; B's fixture declares
-- the reverse edge, so topological scheduling must reject the pair.

register.system{
    id = "test.a",
    after = { "test.b" },
    -- Scheduling should fail before updates run, so the body intentionally
    -- has no behavior beyond satisfying the system contract.
    update = function() end,
}
