local fluffy = {}

-- Fluffy clouds carry visibility and placement behavior; they do not affect occupants on tick.
-- Example: a fluffy cloud can occupy a field cell without adding a per-tick status to its occupant.
function fluffy.apply()
end

return fluffy
