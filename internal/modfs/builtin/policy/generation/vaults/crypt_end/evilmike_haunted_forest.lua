-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local directives = require("constants.vault_directives")
local loot = require("policy.generation.vaults.crypt_end.loot")
local appearance = require("policy.generation.vaults.crypt.appearance")

local handler = {}

-- Select one necromantic patron before resolving its altar and guard roster.
-- Source operation:
-- : if crawl.coinflip() then
-- # Temple of yred
-- KFEAT: _ = altar_yredelemnul
-- KMONS:  9 = patrolling profane servitor
-- KMONS:  H = w:20 patrolling death knight / patrolling profane servitor
-- KMONS:  0 = patrolling ghoul
-- KMONS:  A = patrolling death knight
-- KMONS:  B = skeletal warrior
-- KMONS:  C = necrophage
-- KMONS:  E = phantasmal warrior / w:4 flayed ghost / w:1 phantom / w:1 shadow / nothing
-- KMONS:  F = patrolling bone dragon
-- : else
-- # Temple of kiku - more necromancers, more demonic (kiku's description refers to
-- # him/her/it being demonic). Not as much undead in this set.
-- KFEAT:  _ = altar_kikubaaqudgha
-- KMONS:  9 = patrolling ancient lich / patrolling dread lich
-- KMONS:  H = w:40 patrolling lich / patrolling ancient lich / \
--             patrolling dread lich
-- KMONS:  0 = patrolling reaper w:5 / patrolling soul eater
-- KMONS:  A = patrolling deep elf death mage
-- KMONS:  B = necromancer
-- KMONS:  C = hellwing
-- KMONS:  E = skeleton w:13 / nothing
-- KMONS:  F = patrolling reaper
-- : end
local function choose_patron(api)
    if api:coinflip() then
        -- Temple of yred
        api:emit(directives.KFEAT, "_ = altar_yredelemnul")
        api:emit(directives.KMONS, "9 = patrolling profane servitor")
        api:emit(
            directives.KMONS,
            "H = w:20 patrolling death knight / patrolling profane servitor"
        )
        api:emit(directives.KMONS, "0 = patrolling ghoul")
        api:emit(directives.KMONS, "A = patrolling death knight")
        api:emit(directives.KMONS, "B = skeletal warrior")
        api:emit(directives.KMONS, "C = necrophage")
        api:emit(
            directives.KMONS,
            "E = phantasmal warrior / w:4 flayed ghost / w:1 phantom / w:1 shadow / "
                .. "nothing"
        )
        api:emit(directives.KMONS, "F = patrolling bone dragon")
    else
        -- Temple of kiku - more necromancers, more demonic (kiku's description refers to
        -- him/her/it being demonic). Not as much undead in this set.
        api:emit(directives.KFEAT, "_ = altar_kikubaaqudgha")
        api:emit(
            directives.KMONS,
            "9 = patrolling ancient lich / patrolling dread lich"
        )
        api:emit(
            directives.KMONS,
            "H = w:40 patrolling lich / patrolling ancient lich / patrolling dread lich"
        )
        api:emit(
            directives.KMONS,
            "0 = patrolling reaper w:5 / patrolling soul eater"
        )
        api:emit(directives.KMONS, "A = patrolling deep elf death mage")
        api:emit(directives.KMONS, "B = necromancer")
        api:emit(directives.KMONS, "C = hellwing")
        api:emit(directives.KMONS, "E = skeleton w:13 / nothing")
        api:emit(directives.KMONS, "F = patrolling reaper")
    end
end

handler.choose_patron = choose_patron

-- Keep the gravestone description local to this map.
-- Source operation:
-- : set_feature_name("granite_statue", "gravestone")
local function name_gravestones(api)
    appearance.gravestone(api)
end

handler.name_gravestones = name_gravestones

-- Keep the dead-tree description local to this map.
-- Source operation:
-- : set_feature_name("tree", "dead tree")
local function name_dead_trees(api)
    appearance.dead_tree(api)
end

handler.name_dead_trees = name_dead_trees

-- Add Crypt ending incentives at the authored source position.
-- Source operation:
-- : crypt_loot_plus(_G)
local function bonus_loot(api)
    loot.apply(api)
end

handler.bonus_loot = bonus_loot

return handler
