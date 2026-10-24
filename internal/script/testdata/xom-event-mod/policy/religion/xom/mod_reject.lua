-- A rejected mod action lets the next stable-ID peer spend its own check.
local selector = {}

-- Reject without consuming RNG so the tie-order test is exact.
function selector.eligible()
    return false
end

return selector
