-- This map mixes useful source loot pools with intentionally weak finds.
-- The pool names come from one shared Lua declaration used by other vaults.
local directives = require("constants.vault_directives")
local loot = require("constants.vault_loot")

local crypta = {}

-- Emit one ITEM request so the source alternatives retain their relative
-- weights instead of becoming separate independent placements.
local function loot_mix(api)
    api:emit(directives.ITEM, loot.SCROLLS .. " / " .. loot.POTIONS ..
        " / scroll of noise ident:type w:33 / " ..
        "potion of degeneration ident:type w:33")
end

crypta.loot_mix = loot_mix

return crypta
