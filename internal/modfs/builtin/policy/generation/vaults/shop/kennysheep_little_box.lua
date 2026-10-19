-- Example: The little box delegates its shop-or-temple choice to the shared setup with this map's glyphs.
local setup = require("policy.generation.vaults.shop.kennysheep_setup")

local handler = {}

-- The little box delegates its shop-or-temple choice to the shared setup with this map's glyphs.
local function configure_shop_or_temple(api)
    setup.random_room(api)
    setup.shop_or_temple(api, "{}C....")
end

handler.configure_shop_or_temple = configure_shop_or_temple

return handler
