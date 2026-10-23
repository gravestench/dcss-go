-- Nemelex Xobeh gains ordinary devotion from source exploration pulses.
-- Card generation belongs to the gift owner and does not change this
-- pulse's numerator or its religion RNG draw.
local kinds = require("constants.religion_conduct")

-- The source offers fourteen units of piety over each 2500-unit pulse.
local function explore(_, _, _, _, denominator)
    return 14, denominator
end

local nemelex_xobeh = {
    likes = {
        [kinds.EXPLORATION] = {
            description = "you explore the world",
            bonus = 0,
            denom_bonus = 0,
            xl_denom = 0,
            special = explore,
        },
    },
}

return nemelex_xobeh
