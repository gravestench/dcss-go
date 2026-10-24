-- A simple extension can choose itself without editing the source selector.
local selector = {}

-- Return true after the earlier gates fail; a real mod checks game context.
function selector.eligible()
    return true
end

return selector
