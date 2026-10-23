-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local directives = require("constants.vault_directives")
local loot = require("policy.generation.vaults.crypt_end.loot")

local handler = {}

-- Keep the source stair and loot substitutions in the same random branch.
-- Source operation:
-- : if crawl.x_chance_in_y(5, 7) then
-- SUBST:  O = *
-- NSUBST: P = > / |**
-- : else
-- NSUBST: O = 1:>
-- SUBST:  P = |**
-- : end
local function choose_stair_and_prize(api)
    if api:chance(5, 7) then
        api:emit(directives.SUBST, "O = *")
        api:emit(directives.NSUBST, "P = > / |**")
    else
        api:emit(directives.NSUBST, "O = 1:>")
        api:emit(directives.SUBST, "P = |**")
    end
end

handler.choose_stair_and_prize = choose_stair_and_prize

-- Add Crypt ending incentives at the authored source position.
-- Source operation:
-- : crypt_loot_plus(_G)
local function bonus_loot(api)
    loot.apply(api)
end

handler.bonus_loot = bonus_loot

return handler
