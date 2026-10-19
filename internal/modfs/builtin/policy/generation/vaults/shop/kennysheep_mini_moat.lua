-- Example: First randomize the moated room; its shop-or-temple glyph mapping follows that layout.
local setup = require("policy.generation.vaults.shop.kennysheep_setup")

local handler = {}

-- First randomize the moated room; its shop-or-temple glyph mapping follows that layout.
local function choose_shop_setup(api)
    setup.random_room(api)
end

-- The moated map passes {}CC to the shared feature substitution after room edits.
local function configure_shop_or_temple(api)
    setup.shop_or_temple(api, "{}CC")
end

handler.choose_shop_setup = choose_shop_setup
handler.configure_shop_or_temple = configure_shop_or_temple

return handler
