-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local directives = require("constants.vault_directives")
local loot = require("policy.generation.vaults.crypt_end.loot")

local handler = {}

-- Draw once before the theme directives, preserving the source choice order.
-- Source operation:
-- : local brnd = crawl.random2(13)
local function choose_theme_roll(api)
    api:remember("brnd", api:roll(13))
end

handler.choose_theme_roll = choose_theme_roll

-- Emit one complete source roster so unrelated themes cannot mix on this map.
-- Source operation:
-- : if brnd > 8 then
-- MONS:   ancient lich / dread lich
-- MONS:   bone dragon
-- MONS:   lich
-- MONS:   ancient champion
-- MONS:   skeletal warrior
-- MONS:   flying skull
-- MONS:   w:20 skeletal warrior / w:50 skeleton / nothing
-- # vampire layout
-- : elseif brnd > 4 then
-- KMONS:  1 = vampire knight / Jory w:5, vampire knight
-- KMONS:  2 = phantasmal warrior
-- KMONS:  3 = vampire knight w:15 / \
--             dancing weapon ; long sword ego:vampirism ident:type
-- KMONS:  4 = vampire mage
-- KMONS:  5 = skeletal warrior / phantasmal warrior
-- KMONS:  6 = vampire knight w:15 / jiangshi
-- KMONS:  7 = vampire knight / skeletal warrior / w:15 zombie / wraith / w:5 nothing
-- # ghost layout
-- : elseif brnd > 0 then
-- MONS:   curse skull
-- MONS:   revenant
-- MONS:   lich
-- MONS:   eidolon / flayed ghost
-- MONS:   phantasmal warrior / shadow wraith w:6
-- MONS:   flying skull
-- MONS:   wraith / freezing wraith / shadow wraith / spectral thing / \
--         w:20 shadow / nothing
-- # mummy layout - rare
-- : else
-- MONS:   royal mummy
-- MONS:   sphinx
-- MONS:   mummy priest
-- MONS:   mummy priest
-- MONS:   guardian mummy w:7 / ushabti w:3
-- MONS:   flying skull
-- MONS:   mummy / guardian mummy / w:5 nothing
-- : end
local function theme_monsters(api)
    local brnd = api:recall("brnd")

    if brnd > 8 then
        api:emit(directives.MONS, "ancient lich / dread lich")
        api:emit(directives.MONS, "bone dragon")
        api:emit(directives.MONS, "lich")
        api:emit(directives.MONS, "ancient champion")
        api:emit(directives.MONS, "skeletal warrior")
        api:emit(directives.MONS, "flying skull")
        api:emit(
            directives.MONS,
            "w:20 skeletal warrior / w:50 skeleton / nothing"
        )
    -- vampire layout
    elseif brnd > 4 then
        api:emit(
            directives.KMONS,
            "1 = vampire knight / Jory w:5, vampire knight"
        )
        api:emit(directives.KMONS, "2 = phantasmal warrior")
        api:emit(
            directives.KMONS,
            "3 = vampire knight w:15 / dancing weapon ; long sword ego:vampirism "
                .. "ident:type"
        )
        api:emit(directives.KMONS, "4 = vampire mage")
        api:emit(directives.KMONS, "5 = skeletal warrior / phantasmal warrior")
        api:emit(directives.KMONS, "6 = vampire knight w:15 / jiangshi")
        api:emit(
            directives.KMONS,
            "7 = vampire knight / skeletal warrior / w:15 zombie / wraith / w:5 nothing"
        )
    -- ghost layout
    elseif brnd > 0 then
        api:emit(directives.MONS, "curse skull")
        api:emit(directives.MONS, "revenant")
        api:emit(directives.MONS, "lich")
        api:emit(directives.MONS, "eidolon / flayed ghost")
        api:emit(directives.MONS, "phantasmal warrior / shadow wraith w:6")
        api:emit(directives.MONS, "flying skull")
        api:emit(
            directives.MONS,
            "wraith / freezing wraith / shadow wraith / spectral thing / w:20 shadow / "
                .. "nothing"
        )
    -- mummy layout - rare
    else
        api:emit(directives.MONS, "royal mummy")
        api:emit(directives.MONS, "sphinx")
        api:emit(directives.MONS, "mummy priest")
        api:emit(directives.MONS, "mummy priest")
        api:emit(directives.MONS, "guardian mummy w:7 / ushabti w:3")
        api:emit(directives.MONS, "flying skull")
        api:emit(directives.MONS, "mummy / guardian mummy / w:5 nothing")
    end
end

handler.theme_monsters = theme_monsters

-- Add Crypt ending incentives at the authored source position.
-- Source operation:
-- : crypt_loot_plus(_G)
local function bonus_loot(api)
    loot.apply(api)
end

handler.bonus_loot = bonus_loot

return handler
