-- Theory of operation: the source subway controller has no terrain. Its
-- post-place hook places three station maps; each map owns its destination
-- marker names, so the controller only chooses their shared tag and count.
local handler = {}

-- Delay registry lookup until after vault catalog load has finalized IDs.
-- The tag is shared by the three authored station declarations.
local function place_stations(api)
    local tags = require("constants.vault_tags")

    api:place_maps(tags.SERIAL_NICO_SUBWAY, 3)
end

handler.place_stations = place_stations

return handler
