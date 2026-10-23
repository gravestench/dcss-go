-- The entrance fixes this value once and the visit carries it into every
-- destination hook. A missing value indicates a broken travel contract.
local difficulty = {}

-- Validate instead of silently converting a missing value to easy mode.
function difficulty.hard(api)
    local value = api:setting("ice_cave_hard")

    if type(value) ~= "boolean" then
        error("Ice Cave needs saved easy/hard difficulty")
    end

    return value
end

return difficulty
