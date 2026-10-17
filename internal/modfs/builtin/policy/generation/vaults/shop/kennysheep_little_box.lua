local setup = require("policy.generation.vaults.shop.kennysheep_setup")

local handler = {}

-- Port of builder/shops.des:283-284.
local function configure_shop_or_temple(api)
    setup.random_room(api)
    setup.shop_or_temple(api, "{}C....")
end

handler.configure_shop_or_temple = configure_shop_or_temple

return handler
