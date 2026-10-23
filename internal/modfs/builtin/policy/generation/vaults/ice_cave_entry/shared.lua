-- Theory of operation: each entrance uses the same source timed archway.
-- The origin branch fixes difficulty when the map is placed. Its deadline
-- and difficulty travel together in the marker, then become one ECS gate.
local directives = require("constants.vault_directives")
local ice_cave = require("constants.ice_cave")
local difficulty = require("policy.world.ice_cave.difficulty")

local shared = {}
-- Emit the common feature and its one saved timer. Selection tags and
-- chance live in DES because the selector must see them before this hook.
local function portal(api)
    local turns = ice_cave.MIN_DURATION_TURNS +
        api:roll(ice_cave.DURATION_RANGE_TURNS)
    local hard = difficulty.hard(api:branch_id(), api:depth())

    api:emit(directives.MARKER,
        "O = lua:timed_marker { low = " .. turns ..
        ", high = " .. turns ..
        ", hard = " .. tostring(hard) ..
        ', single_timed = true, floor = "expired_portal", ' ..
        'feat_tile = "dngn_portal_ice_cave_gone", ' ..
        'disappear = "The archway melts and disappears." }')
    api:emit(directives.KFEAT, "O = enter_ice_cave")
    api:emit(directives.COLOUR, "a = white")
    api:emit(directives.KFEAT, "a = x")
    api:emit(directives.RTILE, "a = wall_ice_block")
    api:emit(directives.COLOUR, ".1234 = blue")
    api:emit(directives.FTILE, ".12345O+^ = floor_ice")

    return hard
end

shared.portal = portal

return shared
