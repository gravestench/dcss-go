-- Counting calls reveals whether require reused a cached module or loaded a new one.

local calls = 0

-- Increment module-local state on each invocation so a require-cache test
-- can tell a reused module apart from a freshly loaded overlay.
local function next_call()
    calls = calls + 1

    return calls
end

return next_call
