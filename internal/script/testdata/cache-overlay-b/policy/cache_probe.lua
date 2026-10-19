-- Overlay B replaces the same cache-probe path so stale modules must be discarded.
-- Example: the first call after selecting overlay B returns source B and calls 1.

local policy = {}
local calls = 0

-- Count calls in overlay B's own module state, which should start fresh after
-- the path override replaces overlay A.
function policy.run()
    calls = calls + 1

    return {
        source = "B",
        calls = calls,
    }
end

register.policy({
    id = "test.cache_probe",
    run = policy.run,
})

return policy
