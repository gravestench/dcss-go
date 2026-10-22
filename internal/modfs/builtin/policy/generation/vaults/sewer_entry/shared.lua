-- Theory of operation: every source Sewer entrance keeps its authored DES
-- geometry. This hook adds the common timed drain, messages, and terrain at
-- the source script position, so the portal owner can materialize one ECS
-- clock when the chosen entry is populated. The chance and unique tags
-- are declared statically in each DES file so selection sees them first.
local directives = require("constants.vault_directives")
local sewer = require("constants.sewer")

local shared = {}

-- Draw the source 600–800-turn lifetime once. A fixed low/high marker
-- preserves that draw without asking the population pass to reroll it.
local function portal(api)
    local turns = sewer.MIN_DURATION_TURNS +
        api:roll(sewer.DURATION_RANGE_TURNS)

    api:emit(directives.MARKER,
        "O = lua:timed_marker { low = " .. turns ..
        ", high = " .. turns ..
        ', single_timed = true, floor = "' ..
        sewer.EXPIRED_MARKER_FLOOR .. '" }')
    api:emit(directives.KFEAT, "O = enter_sewer")
    api:emit(directives.KFEAT, "1 = W")
    api:emit(directives.COLOUR, "1W = lightgreen / cyan w:5")
    api:emit(directives.COLOUR, "w = green")
    api:emit(directives.TILE, "x = wall_oozing")
    api:emit(directives.TILE, "c = wall_stone_mossy")
end

shared.portal = portal

return shared
