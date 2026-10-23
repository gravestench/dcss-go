-- Caverns 01 keeps both source decisions at their separate DES sites.
local conditional = require("policy.generation.vaults.ice_cave.conditional")

local map = {}

-- Draw this map's natural versus undead population once.
function map.site_4(api)
    conditional.cavern_monsters(api)
end

-- Apply the saved difficulty to this map's J and K rooms.
function map.site_5(api)
    conditional.cavern_rooms(api)
end

return map
