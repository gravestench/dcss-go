-- Source: cloud.cc:CLOUD_DUST is a short lived visual cloud. It has no
-- damage or status effect when an actor passes through it.
local dust = {}

-- The path marker has no contact effect, so the field engine can call this hook safely.
-- Example: Rolling Charge dust marks its path without damaging an actor standing in the cloud.
function dust.apply()
end

return dust
