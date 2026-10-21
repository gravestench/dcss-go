-- Box Level uses one source coinflip to choose a coherent monster theme.
-- The MAP and all fixed directives remain in DES; these two script sites
-- only fill the shared potion pool and its themed MONS slots.
local directives = require("constants.vault_directives")
local loot = require("constants.vault_loot")

local handler = {}

-- Import the same useful-potion expression used by other source vaults,
-- so a mod updates the pool once instead of editing every KITEM string.
local function loot_potions(api)
    api:emit(directives.KITEM, "g = " .. loot.POTIONS)
end

-- Preserve the single source coinflip: both MONS slots must belong to the
-- same birds-and-elves or spriggans-and-giants encounter.
local function choose_theme(api)
    if api:coinflip() then
        api:emit(directives.MONS,
            "tengu conjurer / tengu warrior / deep elf elementalist / " ..
            "sphinx / nothing")
        api:emit(directives.MONS,
            "tengu reaver / deep elf annihilator / deep elf high priest / " ..
            "caustic shrike")

        return
    end

    api:emit(directives.MONS,
        "spriggan berserker / spriggan air mage / ettin / stone giant / " ..
        "frost giant / fire giant / nothing")
    api:emit(directives.MONS,
        "spriggan defender / titan / juggernaut")
end

handler.loot_potions = loot_potions
handler.choose_theme = choose_theme

return handler
