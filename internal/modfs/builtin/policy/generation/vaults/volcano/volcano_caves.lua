-- Collapsing-cavern doorways have immutable source positions. A separate
-- Akara clock later chooses one surviving M marker per eruption tick.
local effects = require("constants.vault_effects")
local volcano = require("constants.volcano")

local caves = {}

-- The source shared trigger is represented by one typed marker at each M.
-- Population groups them by source vault and resolved record index.
local function doorways(api)
    api:record(effects.MARKER, {
        glyph = "M",
        identity = volcano.COLLAPSE_MARKER,
    })
end

caves.site_1 = doorways

return caves
