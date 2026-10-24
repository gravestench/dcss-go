-- The custom events have an ordinary Lua effect owner, not a Go case.
local effect = {}

-- Report an applied action so the extension can be dispatched by ID.
function effect.apply()
    return true
end

return effect
