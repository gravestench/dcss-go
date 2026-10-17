local setup = require("policy.generation.vaults.shop.kennysheep_setup")

local handler = {}

-- Port of builder/shops.des:269.
local function choose_shop_setup(api)
    setup.random_room(api)
end

-- Port of builder/shops.des:271.
local function configure_shop_or_temple(api)
    setup.shop_or_temple(api, "{}CC")
end

handler.choose_shop_setup = choose_shop_setup
handler.configure_shop_or_temple = configure_shop_or_temple

return handler
