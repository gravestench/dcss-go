-- Caverns 02 uses the shared cave rules with its own authored geometry.
local conditional = require("policy.generation.vaults.ice_cave.conditional")

local map = {}

-- Draw its roster independently of the other cavern maps.
function map.site_4(api)
    conditional.cavern_monsters(api)
end

-- The source J/K substitution follows the monster decision.
function map.site_5(api)
    conditional.cavern_rooms(api)
end

return map
