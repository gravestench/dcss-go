-- Lugonu grants a first worshipper 20 extra piety so the first power is
-- immediately available. Returning worshippers do not receive it again.
local gods = require("constants.gods")
local piety = require("policy.religion.piety")

local lugonu = {}

-- Apply the source's once-only bonus before the common transition records
-- this visit in worshipped; the caller preserves that order for all gods.
function lugonu.join(ctx, player, state)
    if (state.worshipped[gods.LUGONU] or 0) == 0 then
        piety.gain(ctx, player, 20, 1, false)
    end
end

return lugonu
