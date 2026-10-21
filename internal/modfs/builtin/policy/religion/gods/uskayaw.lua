-- Uskayaw's transient piety makes the full Monk bonus misleading; the
-- source awards only 15 points for a first-god Monk.
local piety = require("policy.religion.piety")

local uskayaw = {}

-- Apply the shorter source entry bonus through the common piety owner.
function uskayaw.monk_bonus(ctx, player)
    piety.gain(ctx, player, 15, 1, false)
end

return uskayaw
