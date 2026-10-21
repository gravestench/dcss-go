-- Force a real source arrival through the normal floor builder so game
-- integration tests exercise marker resolution without hunting for a seed.
local vaults = require("ids.vaults")

local selection = {}

-- The fixture uses the committed DES map; only its selection is fixed.
function selection.choose_catalog()
    return {
        id = vaults.spicycebolla_arrival_risky_transporter,
    }
end

-- Supplemental draws are unrelated to passage and would obscure the map.
function selection.choose_tag()
    return nil
end

return selection
