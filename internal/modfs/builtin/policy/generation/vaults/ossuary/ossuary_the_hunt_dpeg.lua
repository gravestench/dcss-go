-- The hunt places one mixed helpful consumable pool near its trap field.
-- Importing the shared pool keeps this map in sync with other source loot.
local directives = require("constants.vault_directives")
local loot = require("constants.vault_loot")

local hunt = {}

-- This is one source ITEM declaration, not one scroll plus one potion.
local function loot_mix(api)
    api:emit(directives.ITEM, loot.SCROLLS .. " / " .. loot.POTIONS)
end

hunt.loot_mix = loot_mix

return hunt
