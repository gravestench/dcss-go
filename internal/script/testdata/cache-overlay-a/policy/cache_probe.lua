local policy = {}
local calls = 0

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
