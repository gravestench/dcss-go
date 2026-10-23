-- Theory of operation: intact and wrecked ruin MAPs share the original
-- desolation_ruins_setup helper. This hook expands its two monster slots,
-- sparse reward substitutions, good-item pool, and column tile at the
-- exact DES position. Maps without the hook keep their authored overrides.
local directives = require("constants.vault_directives")
local loot = require("constants.vault_loot")

local shared = {}

-- The first two monster slots form a saltling group and its commander.
-- Percent cells sometimes survive as treasure and sometimes become floor.
function shared.setup(api)
    api:emit(directives.MONS, "saltling band")
    api:emit(directives.MONS,
        "imperial myrmidon / halazid warlock / crystal guardian")
    api:emit(directives.NSUBST, "% = 4:% / 3:| / *:.")
    api:emit(directives.KITEM,
        "% = any weapon good_item / any armour good_item / " ..
        "any jewellery randart w:5 / randbook w:5")
    api:emit(directives.TILE, "G = DNGN_CRUMBLED_COLUMN")
end

-- The intact library has its own higher-grade scroll slot instead of
-- calling the general ruin helper. Import the shared source pool here.
function shared.good_scrolls(api)
    api:emit(directives.KITEM, "S = " .. loot.GOOD_SCROLLS)
end

return shared
