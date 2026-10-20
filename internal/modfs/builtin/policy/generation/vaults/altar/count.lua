-- The overflow scheduler chooses how many gods a generic map must hold.
-- Read that local placement setting rather than depending on the old DES
-- Lua global. Rejecting absent or out-of-range counts catches broken plans.
local settings = require("constants.vault_settings")

local count = {}

-- Each map supplies its own capacity so the same setting cannot produce an
-- arrangement that has fewer altar slots than the scheduled god group.
function count.selected(api, minimum, maximum)
    local value = api:setting(settings.OVERFLOW_ALTAR_COUNT)

    if type(value) ~= "number" or value % 1 ~= 0 or
        value < minimum or value > maximum then
        error("overflow altar map needs an eligible selected altar count")
    end

    return value
end

return count
