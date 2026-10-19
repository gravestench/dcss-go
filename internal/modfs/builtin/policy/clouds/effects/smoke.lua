-- Source: cloud.cc smoke clouds obscure sight without harming occupants.
local smoke = {}
smoke.opaque = true

-- Opaque smoke changes visibility through cloud state and has no contact damage hook.
-- Example: smoke obscures sight through its opaque cloud record without harming an occupant.
function smoke.apply()
end

return smoke
