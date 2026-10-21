-- Theory of operation: this source mapless controller spends one Swamp
-- decoration slot on a weighted serial ruin. The child owns its MAP and
-- remains eligible when a mod adds another matching ruin definition.
local tags = require("constants.vault_tags")

local handler = {}

-- Ask the effective catalog for exactly one ruin after controller selection.
local function assemble(api)
    api:place_maps(tags.SERIAL_SWAMP_RUIN, 1)
end

handler.assemble = assemble

return handler
