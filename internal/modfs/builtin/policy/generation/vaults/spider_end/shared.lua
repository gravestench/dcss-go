-- Theory of operation: every Spider ending calls one source loot helper.
-- Keep the three independent item requests together so each authored DES
-- file gets the same rewards at its original script position.
local directives = require("constants.vault_directives")

local handler = {}

-- Request the source ambrosia, weighted potion, and auxiliary gear draws.
-- Item generation resolves these ordinary DES requests during population.
local function loot(api)
    api:emit(directives.ITEM, "potion of ambrosia ident:all")
    api:emit(directives.ITEM,
        "w:16 potion of haste / w:16 potion of heal wounds / " ..
        "w:11 potion of might / w:11 potion of invisibility / " ..
        "w:11 potion of magic / w:11 potion of mutation / " ..
        "w:8 potion of cancellation / w:7 potion of brilliance / " ..
        "w:7 potion of resistance / w:2 potion of experience")
    api:emit(directives.ITEM,
        "hat good_item w:20 / pair of gloves good_item / " ..
        "pair of boots good_item / scarf w:40 / orb w:40")
end

handler.loot = loot

return handler
