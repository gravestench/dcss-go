local calls = 0

local function next_call()
    calls = calls + 1

    return calls
end

return next_call
