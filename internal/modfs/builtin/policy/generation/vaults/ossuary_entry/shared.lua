-- Theory of operation: the source shared helper gives every authored
-- entrance one timed gate, sand styling, and the same lifetime draw.
-- Selection tags and chance live statically in DES because the selector
-- runs before this hook. The fixed low/high marker preserves the draw.
local directives = require("constants.vault_directives")
local ossuary = require("constants.ossuary")

local shared = {}

-- Materialization later turns this one marker into one ECS portal clock.
-- A portal whose map never places cannot start a clock or announce itself.
local function portal(api)
    local turns = ossuary.MIN_DURATION_TURNS +
        api:roll(ossuary.DURATION_RANGE_TURNS)

    api:emit(directives.MARKER,
        "O = lua:timed_marker { low = " .. turns ..
        ", high = " .. turns ..
        ', single_timed = true, floor = "' ..
        ossuary.EXPIRED_MARKER_FLOOR .. '" }')
    api:emit(directives.KFEAT, "O = enter_ossuary")
    api:emit(directives.COLOUR, "' = yellow")
    api:emit(directives.FTILE, "' = floor_sandstone")
    api:emit(directives.TILE, "c = wall_tomb")
end

shared.portal = portal

return shared
