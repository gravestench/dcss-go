-- Theory of operation: the one authored entrance draws its lifetime when
-- the O arch is placed. A saved portal entity later uses that exact draw;
-- revisiting the outside floor cannot reset the clock.
local directives = require("constants.vault_directives")
local gauntlet = require("constants.gauntlet")

local shared = {}

-- Emit the marker before KFEAT, as the source helper does. The old timed
-- message object becomes the Gauntlet gate system's live warning policy.
function shared.portal(api)
    local turns = gauntlet.MIN_DURATION_TURNS +
        api:roll(gauntlet.DURATION_RANGE_TURNS)

    api:emit(directives.MARKER,
        "O = lua:timed_marker { low = " .. turns ..
        ", high = " .. turns ..
        ', single_timed = true, entity = "gateway", floor = "' ..
        gauntlet.EXPIRED_FEATURE .. '" }')
    api:emit(directives.KFEAT,
        "O = " .. gauntlet.ENTRY_FEATURE)
end

return shared
