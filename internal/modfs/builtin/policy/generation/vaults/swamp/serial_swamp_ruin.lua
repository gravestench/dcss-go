-- Theory of operation: a selected serial ruin groups two or three source
-- ruins on one floor. Each child gets its own weighted draw and fit attempt.
local tags = require("constants.vault_tags")

local handler = {}

-- The source's random2(2) adds either zero or one extra child.
local function assemble(api)
    local count = 2 + api:roll(2)

    api:place_maps(tags.SERIAL_SWAMP_RUIN, count)
end

handler.assemble = assemble

return handler
