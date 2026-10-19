local salt = {}

-- Salt is kept as a cloud kind even though its occupant hook is intentionally empty.
-- Example: salt cloud exposure has no occupant callback even while the cloud remains placed.
function salt.apply()
end

return salt
