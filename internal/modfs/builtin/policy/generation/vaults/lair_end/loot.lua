-- Theory of operation: the ancient temple's d cell uses DCSS's shared
-- useful-potion pool. The keyed cell stays in DES and the common pool is
-- imported so a change to that pool has one owner.
local directives = require("constants.vault_directives")
local loot = require("constants.vault_loot")

local handler = {}

-- Attach the shared potion expression before source keyed loot is resolved.
local function potions(api)
    api:emit(directives.KITEM, "d = " .. loot.POTIONS)
end

handler.potions = potions

return handler
