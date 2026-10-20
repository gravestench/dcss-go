-- Theory of operation: one source chance roll activates a group of
-- graveyard patches. The children keep their own terrain and depth-scaled
-- zombie rules, while this controller only draws the group size.
local tags = require("constants.vault_tags")
local handler = {}

-- Independent 0..2 and 0..3 draws favor the minimum group size.
local function place_undead(api)
    local count = 4 + api:roll(3) * api:roll(4)

    api:place_maps(tags.SERIAL_UNDEAD, count)
end

handler.place_undead = place_undead

return handler
