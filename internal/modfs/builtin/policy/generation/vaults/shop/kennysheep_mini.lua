-- Example: The mini variant shares shop-or-temple behavior but passes its own entrance glyph set.
local setup = require("policy.generation.vaults.shop.kennysheep_setup")

local handler = {}

-- The mini variant shares shop-or-temple behavior but passes its own entrance glyph set.
local function configure_shop_or_temple(api)
    setup.random_room(api)
    setup.shop_or_temple(api, "{}CC")
end

handler.configure_shop_or_temple = configure_shop_or_temple

return handler
