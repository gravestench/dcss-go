-- Theory of operation: the alternate Swamp decor controller contributes
-- one ordinary tagged decoration, including a mod-added matching map.
local tags = require("constants.vault_tags")

local handler = {}

-- The controller owns selection; the child owns all terrain and actors.
local function assemble(api)
    api:place_maps(tags.DECOR, 1)
end

handler.assemble = assemble

return handler
