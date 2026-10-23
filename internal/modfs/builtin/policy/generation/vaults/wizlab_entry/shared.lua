-- Theory of operation: each of the eleven original Wizard Lab entrances
-- has its own MAP, but the global source helper drew one 600–800-turn
-- timer and attached it to the O arch. This hook performs that draw at
-- the source position and records its value in a typed marker. Population
-- will make one Akara clock from the marker, never draw the timer again.
local directives = require("constants.vault_directives")
local wizlab = require("constants.wizlab")

local shared = {}

-- Preserve the source draw and directive ordering. The old message
-- object belongs to the live gate's notice policy, not this map hook.
function shared.portal(api)
    local turns = wizlab.MIN_DURATION_TURNS +
        api:roll(wizlab.DURATION_RANGE_TURNS)

    api:emit(directives.MARKER,
        "O = lua:timed_marker { low = " .. turns ..
        ", high = " .. turns ..
        ', single_timed = true, entity = "portal", floor = "' ..
        wizlab.EXPIRED_MARKER_FLOOR .. '" }')
    api:emit(directives.KFEAT,
        "O = " .. wizlab.ENTRY_FEATURE)
end

return shared
