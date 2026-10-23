-- Caverns 03 shares decisions with its siblings but owns its map cells.
local conditional = require("policy.generation.vaults.ice_cave.conditional")

local map = {}

-- Select one natural or undead roster for this placement.
function map.site_4(api)
    conditional.cavern_monsters(api)
end

-- Easy caves spread additional rooms; hard caves retain stronger slots.
function map.site_5(api)
    conditional.cavern_rooms(api)
end

return map
