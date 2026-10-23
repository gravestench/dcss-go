-- Theory of operation: every source Trove entrance invokes this hook at
-- its authored DES position. Placement records the gate and an empty price;
-- population later rolls a toll against the actual player and stores it in
-- the ECS gate. This prevents a layout retry from changing player policy.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")

local shared = {}

-- Keep the source marker on O, where travel can match its typed price to
-- the saved gate. The following directives retain the source's appearance.
local function portal(api)
    api:record(effects.MARKER, {
        glyph = "O",
        identity = "trove:toll",
        price = "",
    })
    api:emit(directives.KFEAT, "O = enter_trove")
    api:emit(directives.COLOUR, ". = blue")
    api:emit(directives.FTILE, ".OcG+ = floor_marble")
    api:emit(directives.TILE, "c = wall_stone_dark")
end

shared.portal = portal

return shared
