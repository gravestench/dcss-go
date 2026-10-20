-- Theory of operation: the source's rare controller creates no terrain.
-- When selected, it asks the vault picker for four to six rooms carrying
-- the research tag. Each child retains its own source DES map and school.
local tags = require("constants.vault_tags")
local handler = {}

-- The controller draws one bounded number so the number of rooms is stable
-- for a given layout stream and does not depend on file discovery order.
local function place_research(api)
    local count = 4 + api:roll(3)

    api:place_maps(tags.SERIAL_RESEARCH, count)
end

handler.place_research = place_research

return handler
