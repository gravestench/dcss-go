-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local directives = require("constants.vault_directives")
local loot = require("policy.generation.vaults.crypt_end.loot")

local handler = {}

-- One weighted source branch supplies the complete final guard group.
-- Source operation:
-- : if crawl.one_chance_in(4) then
-- KMONS:   R = Khufu, royal mummy
-- KMONS:   S = mummy priest
-- KMONS:   T = guardian mummy
-- : elseif crawl.one_chance_in(3) then
-- KMONS:   R = Jory, vampire knight
-- KMONS:   S = vampire knight / vampire mage
-- KMONS:   T = vampire knight / jiangshi
-- : elseif crawl.coinflip() then
-- KMONS:   R = ancient lich / dread lich
-- KMONS:   S = flayed ghost
-- KMONS:   T = phantasmal warrior
-- : else
-- KMONS:   R = curse skull
-- KMONS:   S = ancient champion
-- KMONS:   T = skeletal warrior
-- : end
local function choose_guardians(api)
    if api:one_in(4) then
        api:emit(directives.KMONS, "R = Khufu, royal mummy")
        api:emit(directives.KMONS, "S = mummy priest")
        api:emit(directives.KMONS, "T = guardian mummy")
    elseif api:one_in(3) then
        api:emit(directives.KMONS, "R = Jory, vampire knight")
        api:emit(directives.KMONS, "S = vampire knight / vampire mage")
        api:emit(directives.KMONS, "T = vampire knight / jiangshi")
    elseif api:coinflip() then
        api:emit(directives.KMONS, "R = ancient lich / dread lich")
        api:emit(directives.KMONS, "S = flayed ghost")
        api:emit(directives.KMONS, "T = phantasmal warrior")
    else
        api:emit(directives.KMONS, "R = curse skull")
        api:emit(directives.KMONS, "S = ancient champion")
        api:emit(directives.KMONS, "T = skeletal warrior")
    end
end

handler.choose_guardians = choose_guardians

-- Add Crypt ending incentives at the authored source position.
-- Source operation:
-- : crypt_loot_plus(_G)
local function bonus_loot(api)
    loot.apply(api)
end

handler.bonus_loot = bonus_loot

return handler
