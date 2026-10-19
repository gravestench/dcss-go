-- Overlay A provides one cache-probe implementation for require invalidation tests.
-- Example: the first call after selecting overlay A returns source A and calls 1.

local policy = {}
local calls = 0

-- Count calls in overlay A's module-local state, making stale require-cache
-- reuse visible when the active mod layer changes.
function policy.run()
    calls = calls + 1

    return {
        source = "A",
        calls = calls,
    }
end

register.policy({
    id = "test.cache_probe",
    run = policy.run,
})

return policy
