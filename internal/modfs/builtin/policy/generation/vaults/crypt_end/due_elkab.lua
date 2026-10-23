-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local directives = require("constants.vault_directives")
local loot = require("policy.generation.vaults.crypt_end.loot")

local handler = {}

-- Draw once before the theme directives, preserving the source choice order.
-- Source operation:
-- : local brnd = crawl.random2(15)
local function choose_theme_roll(api)
    api:remember("brnd", api:roll(15))
end

handler.choose_theme_roll = choose_theme_roll

-- Emit one complete source roster so unrelated themes cannot mix on this map.
-- Source operation:
-- : if brnd > 10 then
-- MONS:   patrolling skeletal warrior w:8 / patrolling wight
-- MONS:   ancient lich / dread lich
-- MONS:   bone dragon w:1 / ancient champion / lich w:1
-- MONS:   caustic shrike skeleton / titan skeleton
-- MONS:   w:50 skeleton / wight
-- MONS:   generate_awake bone dragon / generate_awake curse toe
-- : elseif brnd > 6 then
-- MONS:   patrolling vampire knight / patrolling vampire mage / \
--         patrolling vampire w:25
-- KMONS:  2 = vampire knight / Jory w:15, vampire knight
-- KMONS:  3 = dancing weapon ; long sword ego:vampirism / vampire knight
-- KMONS:  4 = phantasmal warrior / jiangshi
-- KMONS:  5 = vampire / zombie / golden dragon zombie w:3 / storm dragon zombie w:3
-- KMONS:  6 = generate_awake vampire mage
-- SUBST:  2 = ., ' = 2, " = 4
-- : elseif brnd > 2 then
-- MONS:   patrolling freezing wraith / patrolling spectral thing w:8
-- MONS:   revenant
-- MONS:   eidolon
-- MONS:   flayed ghost / phantasmal warrior
-- MONS:   spectral thing / simulacrum / shadow w:3 / wraith w:2 / shadow wraith / \
--         spectral storm dragon w:5 / spectral quicksilver dragon w:5
-- MONS:   generate_awake shadow dragon / generate_awake ghost moth
-- SUBST:  2 = ., ' = 2, " = 4
-- : else
-- MONS:   patrolling guardian mummy w:7 / patrolling ushabti w:3
-- MONS:   royal mummy
-- MONS:   mummy priest / ushabti w:6
-- MONS:   guardian mummy ; long sword | great sword | \
--         battleaxe | war axe | broad axe . chain mail w:15 | plate armour w:1
-- MONS:   bog body / mummy / guardian mummy
-- MONS:   generate_awake sphinx
-- : end
local function theme_monsters(api)
    local brnd = api:recall("brnd")

    if brnd > 10 then
        api:emit(
            directives.MONS,
            "patrolling skeletal warrior w:8 / patrolling wight"
        )
        api:emit(directives.MONS, "ancient lich / dread lich")
        api:emit(
            directives.MONS,
            "bone dragon w:1 / ancient champion / lich w:1"
        )
        api:emit(directives.MONS, "caustic shrike skeleton / titan skeleton")
        api:emit(directives.MONS, "w:50 skeleton / wight")
        api:emit(
            directives.MONS,
            "generate_awake bone dragon / generate_awake curse toe"
        )
    elseif brnd > 6 then
        api:emit(
            directives.MONS,
            "patrolling vampire knight / patrolling vampire mage / patrolling vampire "
                .. "w:25"
        )
        api:emit(
            directives.KMONS,
            "2 = vampire knight / Jory w:15, vampire knight"
        )
        api:emit(
            directives.KMONS,
            "3 = dancing weapon ; long sword ego:vampirism / vampire knight"
        )
        api:emit(directives.KMONS, "4 = phantasmal warrior / jiangshi")
        api:emit(
            directives.KMONS,
            "5 = vampire / zombie / golden dragon zombie w:3 / storm dragon zombie w:3"
        )
        api:emit(directives.KMONS, "6 = generate_awake vampire mage")
        api:emit(directives.SUBST, "2 = ., ' = 2, \" = 4")
    elseif brnd > 2 then
        api:emit(
            directives.MONS,
            "patrolling freezing wraith / patrolling spectral thing w:8"
        )
        api:emit(directives.MONS, "revenant")
        api:emit(directives.MONS, "eidolon")
        api:emit(directives.MONS, "flayed ghost / phantasmal warrior")
        api:emit(
            directives.MONS,
            "spectral thing / simulacrum / shadow w:3 / wraith w:2 / shadow wraith / "
                .. "spectral storm dragon w:5 / spectral quicksilver dragon w:5"
        )
        api:emit(
            directives.MONS,
            "generate_awake shadow dragon / generate_awake ghost moth"
        )
        api:emit(directives.SUBST, "2 = ., ' = 2, \" = 4")
    else
        api:emit(
            directives.MONS,
            "patrolling guardian mummy w:7 / patrolling ushabti w:3"
        )
        api:emit(directives.MONS, "royal mummy")
        api:emit(directives.MONS, "mummy priest / ushabti w:6")
        api:emit(
            directives.MONS,
            "guardian mummy ; long sword | great sword | battleaxe | war axe | broad axe "
                .. ". chain mail w:15 | plate armour w:1"
        )
        api:emit(directives.MONS, "bog body / mummy / guardian mummy")
        api:emit(directives.MONS, "generate_awake sphinx")
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
