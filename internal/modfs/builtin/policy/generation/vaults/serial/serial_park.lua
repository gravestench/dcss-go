-- Theory of operation: a source one-percent chance activates a park on
-- an open Dungeon layout. Its post-place hook then asks for five to seven
-- weighted park pieces; each piece owns its own terrain and nested gardens.
local tags = require("constants.vault_tags")
local handler = {}

-- Independent small draws give five pieces most often while sometimes
-- requesting six or seven. Shared placement counts only children that fit.
local function place_park(api)
    local count = 5 + api:roll(3) * api:roll(2)

    api:place_maps(tags.SERIAL_PARK, count)
end

handler.place_park = place_park

return handler
