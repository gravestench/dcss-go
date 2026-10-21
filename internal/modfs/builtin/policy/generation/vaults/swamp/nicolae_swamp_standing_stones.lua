-- Theory of operation: two authored loot glyphs draw from the source's
-- common useful potion and scroll lists. The weighted lists are shared
-- constants; DES still owns the glyphs and the other static loot slots.
local directives = require("constants.vault_directives")
local loot = require("constants.vault_loot")

local handler = {}

-- Extend each favored local pair with the pinned source common pool.
local function configure_loot(api)
    api:emit(directives.KITEM,
        "d = potion of magic w:30 / potion of brilliance w:30 / " ..
        loot.POTIONS)
    api:emit(directives.KITEM,
        "e = scroll of summoning w:30 / scroll of blinking w:30 / " ..
        "scroll of vulnerability / " ..
        loot.SCROLLS)
end

handler.configure_loot = configure_loot

return handler
