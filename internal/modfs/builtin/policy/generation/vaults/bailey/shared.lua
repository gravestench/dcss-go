-- Theory of operation: Bailey's source layouts call a small shared set of
-- monster loadouts and loot expressions. Each call emits one declaration at
-- its authored DES position; the placement owner draws the actual actor or
-- item once when it resolves that declaration.
local directives = require("constants.vault_directives")
local loot = require("constants.vault_loot")

local shared = {}

-- Every destination maps its `<` glyph to the temporary branch exit.
-- The travel policy later uses the saved outside site, not a stair depth.
local function setup(api)
    api:emit(directives.KFEAT, "< = exit_bailey")
end

-- The source's ordinary useful potion pool is a single weighted ITEM
-- request. It is not one request for every potion alternative.
local function loot_potions(api)
    api:emit(directives.ITEM, loot.POTIONS)
end

-- The paired source pools are alternatives in one reward slot, whether
-- the source wrote potions first or scrolls first.
local function loot_mix(api)
    api:emit(directives.ITEM, loot.POTIONS .. " / " .. loot.SCROLLS)
end

-- This particular axe keep lists scrolls first in its source expression.
-- Preserve alternative order because the same random draw uses that list.
local function loot_scrolls_then_potions(api)
    api:emit(directives.ITEM, loot.SCROLLS .. " / " .. loot.POTIONS)
end

-- This axe castle binds the mixed consumable pool to its `f` cells
-- rather than placing an unkeyed reward elsewhere on the floor.
local function f_loot_mix(api)
    api:emit(directives.KITEM,
        "f = " .. loot.POTIONS .. " / " .. loot.SCROLLS)
end

-- The source also defines a mixed kobold/hobgoblin boomerang pool for
-- authored or modded axe maps. It stays one weighted monster request.
local function axe_returning(api)
    api:emit(directives.MONS,
        "generate_awake kobold ; boomerang ident:type q:2 | " ..
        "boomerang ident:type q:1 / " ..
        "generate_awake hobgoblin ; boomerang ident:type q:2 | " ..
        "boomerang ident:type q:1")
end

-- Returning boomerangs are the source's ranged support for kobolds.
-- The two quantity alternatives retain their authored equal weights.
local function kobold_axe_returning(api)
    api:emit(directives.MONS,
        "generate_awake kobold ; boomerang ident:type q:2 | " ..
        "boomerang ident:type q:1")
end

-- The easier axe pool mixes common guards with light armour. The source
-- weights make ordinary orcs and goblins more common than orc warriors.
local function easy_axe_fighter(api)
    api:emit(directives.MONS,
        "w:3 orc warrior ; hand axe w:60 | war axe . ring mail / " ..
        "w:7 gnoll ; hand axe w:60 | war axe . leather armour / " ..
        "w:10 hobgoblin ; hand axe w:60 | war axe . leather armour / " ..
        "w:10 orc ; hand axe w:60 | war axe . leather armour / " ..
        "w:12 goblin ; hand axe w:60 | war axe . leather armour")
end

-- Strong axe guards receive heavier axes and armour. Keep one weighted
-- monster expression so the source actor and equipment rolls stay linked.
local function hard_axe_fighter(api)
    api:emit(directives.MONS,
        "w:9 orc warrior ; war axe | broad axe w:2 | " ..
        "battleaxe w:1 . ring mail | scale mail | " ..
        "chain mail | plate armour / " ..
        "w:1 orc knight ; war axe | broad axe w:2 | " ..
        "battleaxe w:1 . ring mail | scale mail | " ..
        "chain mail | plate armour")
end

-- The axe boss's rare executioner's axe keeps the source one-part weight
-- beside its more common battleaxe and broad axe alternatives.
local function orc_warlord_with_axe(api)
    api:emit(directives.MONS,
        "orc warlord ; battleaxe good_item | " ..
        "broad axe good_item | executioner's axe good_item w:1 . " ..
        "chain mail w:20 | plate armour | " ..
        "crystal plate armour w:1")
end

-- Ordinary orcs carry the spear, trident, or halberd that defines the
-- polearm theme, with source medium-armour alternatives.
local function orc_with_polearm(api)
    api:emit(directives.MONS,
        "orc ; spear | trident | halberd . " ..
        "ring mail | scale mail | chain mail")
end

-- Warriors add glaives and the rarer bardiche without changing the
-- common orc pool's equipment odds.
local function orc_warrior_with_polearm(api)
    api:emit(directives.MONS,
        "orc warrior ; spear w:5 | trident w:5 | halberd | " ..
        "glaive | bardiche w:1 . ring mail | scale mail | " ..
        "chain mail | plate armour | crystal plate armour w:1")
end

-- Knights favor tridents and heavy polearms. This remains a separate
-- source MONS declaration so a map can request only its chosen loadouts.
local function orc_knight_with_polearm(api)
    api:emit(directives.MONS,
        "orc knight ; trident w:5 | halberd | glaive | " ..
        "bardiche w:1 . ring mail | scale mail | chain mail | " ..
        "plate armour | crystal plate armour w:1")
end

-- The source has a polearm warlord helper even where a particular map
-- does not call it; keep the authored loadout available to modded maps.
local function orc_warlord_with_polearm(api)
    api:emit(directives.MONS,
        "orc warlord ; halberd good_item | glaive good_item | " ..
        "bardiche good_item w:1 . chain mail w:20 | " ..
        "plate armour | crystal plate armour w:1")
end

shared.setup = setup
shared.loot_potions = loot_potions
shared.loot_mix = loot_mix
shared.loot_scrolls_then_potions = loot_scrolls_then_potions
shared.f_loot_mix = f_loot_mix
shared.axe_returning = axe_returning
shared.kobold_axe_returning = kobold_axe_returning
shared.easy_axe_fighter = easy_axe_fighter
shared.hard_axe_fighter = hard_axe_fighter
shared.orc_warlord_with_axe = orc_warlord_with_axe
shared.orc_with_polearm = orc_with_polearm
shared.orc_warrior_with_polearm = orc_warrior_with_polearm
shared.orc_knight_with_polearm = orc_knight_with_polearm
shared.orc_warlord_with_polearm = orc_warlord_with_polearm

return shared
