-- Theory of operation: aquarium bridges compose smaller DES subvaults.
-- One side is forced open so a player can reach the middle; the other
-- sides may be a bridge, wall, window, or balcony. Once sides are chosen,
-- shared corner rules choose clear or solid glass at their junctions.
-- Geometry remains in the parent and helper `.des` files.
local directives = require("constants.vault_directives")
local bridge = {}

local NONBRIDGE = "aquarium_subvault_wall:3 / " ..
    "aquarium_subvault_window:2 / " ..
    "aquarium_subvault_balcony:1"

-- The source helper weights walls, windows, and balconies 3:2:1 when a
-- bridge is not selected. A generic SUBVAULT directive embeds the result.
local function nonbridge(api, glyph)
    api:emit(directives.SUBVAULT, glyph .. " : " .. NONBRIDGE)
end

-- A forced side consumes no chance draw. Every other side has the source
-- two-in-eight chance to become a bridge before choosing its alternative.
local function choose_side(api, glyph, forced)
    if forced or api:roll(8) < 2 then
        api:emit(directives.SUBVAULT,
            glyph .. " : aquarium_subvault_bridge")

        return true
    end

    nonbridge(api, glyph)

    return false
end

-- Equal bridge states need a stone corner; an open and closed side meet
-- at clear glass. Assign the one destination glyph after both choices.
local function corner(api, glyph, left, right)
    local wall = left == right and "c" or "m"

    api:emit(directives.SUBST, glyph .. " = " .. wall)
end

-- The square has four possible entrances and a forced one. Its four
-- corner glyphs depend on adjacent side states.
local function square(api)
    local forced = api:roll(4)
    local p = choose_side(api, "p", forced == 0)
    local q = choose_side(api, "q", forced == 1)
    local r = choose_side(api, "r", forced == 2)
    local s = choose_side(api, "s", forced == 3)

    corner(api, "J", p, q)
    corner(api, "K", q, r)
    corner(api, "L", r, s)
    corner(api, "M", s, p)
end

-- Both long shapes use these four outer corners after six side decisions.
local function long_corners(api, p, q, r, s, y, z)
    corner(api, "J", p, q)
    corner(api, "K", q, r)
    corner(api, "L", s, y)
    corner(api, "M", y, z)
end

-- A single forced side among six joins both halves of this long bridge.
-- The central N/O/P/Q cells become stone beside a chosen bridge.
local function long_joined(api)
    local forced = api:roll(6)
    local p = choose_side(api, "p", forced == 0)
    local q = choose_side(api, "q", forced == 1)
    local r = choose_side(api, "r", forced == 2)
    local s = choose_side(api, "s", forced == 3)
    local y = choose_side(api, "y", forced == 4)
    local z = choose_side(api, "z", forced == 5)

    api:emit(directives.SUBST, "N = " .. (p and "c" or "m"))
    api:emit(directives.SUBST, "O = " .. (r and "c" or "m"))
    api:emit(directives.SUBST, "P = " .. (s and "c" or "m"))
    api:emit(directives.SUBST, "Q = " .. (z and "c" or "m"))
    long_corners(api, p, q, r, s, y, z)
end

-- A separate forced side on each half keeps both banks accessible. The
-- four central glyph assignments are reversed from the joined shape.
local function long_separate(api)
    local forced_left = api:roll(3)
    local forced_right = api:roll(3)
    local p = choose_side(api, "p", forced_left == 0)
    local q = choose_side(api, "q", forced_left == 1)
    local r = choose_side(api, "r", forced_left == 2)
    local s = choose_side(api, "s", forced_right == 0)
    local y = choose_side(api, "y", forced_right == 1)
    local z = choose_side(api, "z", forced_right == 2)

    api:emit(directives.SUBST, "N = " .. (p and "m" or "c"))
    api:emit(directives.SUBST, "O = " .. (r and "m" or "c"))
    api:emit(directives.SUBST, "P = " .. (s and "m" or "c"))
    api:emit(directives.SUBST, "Q = " .. (z and "m" or "c"))
    long_corners(api, p, q, r, s, y, z)
end

-- Island maps use one forced side and set each corner from that side
-- directly. Their center comes from a separate authored SUBVAULT rule.
local function island(api)
    local forced = api:roll(4)

    for index, glyph in ipairs({ "p", "q", "r", "s" }) do
        local chosen = choose_side(api, glyph, forced == index - 1)
        local corner_glyph = ({ "J", "K", "L", "M" })[index]

        api:emit(directives.SUBST,
            corner_glyph .. " = " .. (chosen and "c" or "m"))
    end
end

-- The straight bridge already has fixed p and r entrances in DES. Only
-- its q side uses the weighted nonbridge helper.
local function nonbridge_q(api)
    nonbridge(api, "q")
end

-- The straight bridge's s side uses the same source helper weights.
local function nonbridge_s(api)
    nonbridge(api, "s")
end

bridge.square = square
bridge.long_joined = long_joined
bridge.long_separate = long_separate
bridge.island = island
bridge.nonbridge_q = nonbridge_q
bridge.nonbridge_s = nonbridge_s

return bridge
