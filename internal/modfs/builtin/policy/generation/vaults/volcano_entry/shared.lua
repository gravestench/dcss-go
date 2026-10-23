-- Theory of operation: every source Volcano entrance calls one timed
-- portal helper. The source draws a single lifetime when placing the
-- vault; population later turns this authored marker into one ECS clock.
local directives = require("constants.vault_directives")
local volcano = require("constants.volcano")

local entry = {}

-- Emit the marker before the feature, then the source wall and floor
-- decoration. Tags and chance live statically in DES for early selection.
local function portal(api)
    local turns = volcano.MIN_DURATION_TURNS +
        api:roll(volcano.DURATION_RANGE_TURNS)

    api:emit(directives.MARKER,
        "O = lua:timed_marker { low = " .. turns ..
        ", high = " .. turns ..
        ', single_timed = true, floor = "expired_portal", ' ..
        'feat_tile = "dngn_portal_volcano_gone", ' ..
        'entity = "tunnel", ' ..
        'disappear = "There is a deep roar from within the tunnel. ' ..
        'Moments later, a river of lava pours forth, ' ..
        'sealing it permanently." }')
    api:emit(directives.KFEAT,
        "O = " .. volcano.ENTRY_FEATURE)
    api:emit(directives.KFEAT, "S = .")
    api:emit(directives.COLOUR, "XS = red")
    api:emit(directives.RTILE, "X = wall_volcanic")
    api:emit(directives.KFEAT, "X = rock_wall")
    api:emit(directives.FTILE, "OS = floor_rough_red")
end

entry.portal = portal

return entry
