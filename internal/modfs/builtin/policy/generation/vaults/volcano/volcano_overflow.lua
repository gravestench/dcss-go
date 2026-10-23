-- Overflow's A/B/C glyphs are source-position lava groups. Its M marker
-- owns the single 200–400-aut phase clock once population materializes it.
local effects = require("constants.vault_effects")
local volcano = require("constants.volcano")

local overflow = {}

-- Save the three conversion groups and the one phase driver as typed
-- records. The active-floor Lua hazard owner changes the grid later.
local function markers(api)
    api:record(effects.MARKER, {
        glyph = "A",
        identity = volcano.OVERFLOW_CELL_PREFIX .. "2",
    })
    api:record(effects.MARKER, {
        glyph = "B",
        identity = volcano.OVERFLOW_CELL_PREFIX .. "4",
    })
    api:record(effects.MARKER, {
        glyph = "C",
        identity = volcano.OVERFLOW_CELL_PREFIX .. "6",
    })
    api:record(effects.MARKER, {
        glyph = "M",
        identity = volcano.OVERFLOW_CLOCK_MARKER,
    })
end

overflow.site_1 = markers

return overflow
