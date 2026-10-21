-- Theory of operation: a small source Lair ending is followed by one more
-- source ending carrying lair_end_small. Restrict the draw to this family
-- and explicitly exclude the primary: modded maps may permit duplicates.
-- Child hooks are not replayed, giving the source persistence guard's
-- one-level effect without keeping a global or recursion flag.
local tags = require("constants.vault_tags")
local families = require("constants.vault_families")

local handler = {}

-- A failed child fit rejects this floor so generation can redraw it.
local function pair(api)
    local options = {
        family = families.LAIR_END,
        exclude_id = api.controller_id,
    }

    if api:place_maps(tags.LAIR_END_SMALL, 1, options) ~= 1 then
        -- The floor builder recognizes this fit failure and redraws its
        -- base layout while keeping the already selected primary ending.
        error("end vault could not fit on base layout: " ..
            "small Lair ending has no fitting partner")
    end
end

handler.pair = pair

return handler
