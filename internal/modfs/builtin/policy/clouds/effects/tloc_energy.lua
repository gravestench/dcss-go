-- Source: cloud.cc:CLOUD_TLOC_ENERGY marks a teleport's old square without
-- dealing damage or changing status.
local energy = {}
energy.opaque = true

-- Teleport energy is a visibility marker, so occupancy alone has no damage effect.
-- Example: a teleport's opaque energy marker changes visibility but not occupant HP.
function energy.apply()
end

return energy
