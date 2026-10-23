-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local directives = require("constants.vault_directives")
local loot = require("policy.generation.vaults.crypt_end.loot")

local handler = {}

-- Choose one of the two opposed source armies for this quadrant.
-- Source operation:
-- : if crawl.coinflip() then
-- KMONS:  H = vampire knight
-- KMONS:  I = vampire mage
-- KMONS:  J = jiangshi
-- KMONS:  P = vampire / zombie / skeleton
-- : else
-- KMONS:  H = sphinx
-- KMONS:  I = guardian mummy w:7 / ushabti w:3
-- KMONS:  J = guardian mummy / mummy
-- KMONS:  P = skeleton / mummy
-- : end
local function choose_vampire_or_mummy(api)
    if api:coinflip() then
        api:emit(directives.KMONS, "H = vampire knight")
        api:emit(directives.KMONS, "I = vampire mage")
        api:emit(directives.KMONS, "J = jiangshi")
        api:emit(directives.KMONS, "P = vampire / zombie / skeleton")
    else
        api:emit(directives.KMONS, "H = sphinx")
        api:emit(directives.KMONS, "I = guardian mummy w:7 / ushabti w:3")
        api:emit(directives.KMONS, "J = guardian mummy / mummy")
        api:emit(directives.KMONS, "P = skeleton / mummy")
    end
end

handler.choose_vampire_or_mummy = choose_vampire_or_mummy

-- Keep the bone and spirit wings independently randomized.
-- Source operation:
-- : if crawl.coinflip() then
-- KMONS:  Z = patrolling curse skull
-- KMONS:  Q = bone dragon
-- KMONS:  R = skeletal warrior
-- KMONS:  S = zombie / skeleton
-- : else
-- KMONS:  Z = patrolling curse skull
-- KMONS:  Q = eidolon
-- KMONS:  R = phantasmal warrior / flayed ghost w:8
-- KMONS:  S = shadow / wraith / freezing wraith / shadow wraith / wight
-- : end
local function choose_bone_or_spirit(api)
    if api:coinflip() then
        api:emit(directives.KMONS, "Z = patrolling curse skull")
        api:emit(directives.KMONS, "Q = bone dragon")
        api:emit(directives.KMONS, "R = skeletal warrior")
        api:emit(directives.KMONS, "S = zombie / skeleton")
    else
        api:emit(directives.KMONS, "Z = patrolling curse skull")
        api:emit(directives.KMONS, "Q = eidolon")
        api:emit(directives.KMONS, "R = phantasmal warrior / flayed ghost w:8")
        api:emit(
            directives.KMONS,
            "S = shadow / wraith / freezing wraith / shadow wraith / wight"
        )
    end
end

handler.choose_bone_or_spirit = choose_bone_or_spirit

-- Keep the fire and hell wings independently randomized.
-- Source operation:
-- : if crawl.coinflip() then
-- KMONS:  t = fire giant skeleton / fire dragon skeleton
-- KMONS:  X = w:1 curse skull / w:19 revenant
-- : else
-- KMONS:  t = w:20 hell knight / smoke demon / red devil
-- KMONS:  X = w:1 curse skull / w:19 hell knight
-- : end
local function choose_fire_or_hell(api)
    if api:coinflip() then
        api:emit(
            directives.KMONS,
            "t = fire giant skeleton / fire dragon skeleton"
        )
        api:emit(directives.KMONS, "X = w:1 curse skull / w:19 revenant")
    else
        api:emit(
            directives.KMONS,
            "t = w:20 hell knight / smoke demon / red devil"
        )
        api:emit(directives.KMONS, "X = w:1 curse skull / w:19 hell knight")
    end
end

handler.choose_fire_or_hell = choose_fire_or_hell

-- Choose one authored Tomb gate and replace every unused candidate glyph.
-- Source operation:
-- : if crawl.one_chance_in(4) then
-- KFEAT:  L = enter_tomb
-- KFEAT:  _ = altar_kikubaaqudgha
-- SUBST:  O = $
-- : elseif crawl.one_chance_in(3) then
-- KFEAT:  _ = enter_tomb
-- SUBST:  O = $
-- : else
-- KFEAT:  _ = altar_kikubaaqudgha
-- NSUBST: O = 1:> / *:$
-- KFEAT:  > = enter_tomb
-- : end
local function choose_tomb_gate(api)
    if api:one_in(4) then
        api:emit(directives.KFEAT, "L = enter_tomb")
        api:emit(directives.KFEAT, "_ = altar_kikubaaqudgha")
        api:emit(directives.SUBST, "O = $")
    elseif api:one_in(3) then
        api:emit(directives.KFEAT, "_ = enter_tomb")
        api:emit(directives.SUBST, "O = $")
    else
        api:emit(directives.KFEAT, "_ = altar_kikubaaqudgha")
        api:emit(directives.NSUBST, "O = 1:> / *:$")
        api:emit(directives.KFEAT, "> = enter_tomb")
    end
end

handler.choose_tomb_gate = choose_tomb_gate

-- Add Crypt ending incentives at the authored source position.
-- Source operation:
-- : crypt_loot_plus(_G)
local function bonus_loot(api)
    loot.apply(api)
end

handler.bonus_loot = bonus_loot

return handler
