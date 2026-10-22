-- Theory of operation: the source Sewer floors carry their geometry and
-- content in DES. These named hooks only express the original shared Lua
-- helpers: exit conversion, water colours, common loot pools, and one
-- two-theme church. The keyed item expressions import the same pool that
-- other vaults use, so a mod can change a pool without editing every map.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local loot = require("constants.vault_loot")

local shared = {}

-- The source exit is the upward glyph. It returns to the saved outside
-- drain rather than becoming an ordinary Dungeon stair link.
local function setup(api)
    api:emit(directives.KFEAT, "< = exit_sewer")
    api:emit(directives.COLOUR, "w = green")
    api:emit(directives.COLOUR, "W = lightgreen")
end

-- Mixed consumables and equipment replace the source dgn.loot_potions
-- expression while keeping the extra alternatives at their authored odds.
local function loot_mixed(api)
    api:emit(directives.ITEM, loot.POTIONS ..
        " / any scroll w:30 / any armour / any weapon")
end

-- A source ITEM declaration chooses one ordinary useful potion.
local function loot_potions(api)
    api:emit(directives.ITEM, loot.POTIONS)
end

-- A source ITEM declaration chooses one ordinary useful scroll.
local function loot_scrolls(api)
    api:emit(directives.ITEM, loot.SCROLLS)
end

-- This map often draws no reward; retain that large no-item weight.
local function loot_sparse(api)
    api:emit(directives.ITEM, loot.POTIONS .. " / " .. loot.SCROLLS ..
        " / nothing w:300")
end

-- The door Sewer adds ordinary armour to its consumable pool.
local function loot_armour(api)
    api:emit(directives.ITEM, loot.POTIONS .. " / " .. loot.SCROLLS ..
        " / any armour")
end

-- Keep all six source auxiliary-armour alternatives equally selectable.
local function loot_aux_armour(api)
    api:emit(directives.ITEM, loot.AUX_ARMOUR)
end

-- Source KITEM uses a local glyph, unlike unkeyed ITEM declarations.
local function question_potions(api)
    api:emit(directives.KITEM, "? = " .. loot.POTIONS)
end

-- The exclamation glyph binds the scroll pool to authored treasure cells.
local function bang_scrolls(api)
    api:emit(directives.KITEM, "! = " .. loot.SCROLLS)
end

-- The tree Sewer has two other keyed item positions, not ? and !.
local function e_potions(api)
    api:emit(directives.KITEM, "e = " .. loot.POTIONS)
end

-- Keep the tree Sewer's scrolls bound to the f cells beside its potions.
local function f_scrolls(api)
    api:emit(directives.KITEM, "f = " .. loot.SCROLLS)
end

-- A window retains its source name as typed presentation intent. The
-- clear-stone-wall terrain itself remains part of the DES geometry.
local function clear_stone_window(api)
    api:record(effects.FEATURE_NAME, {
        feature = "clear_stone_wall",
        name = "large window",
    })
end

-- The church chooses one complete altar and boss theme with one coinflip.
-- Emitting each branch in source order keeps the boss, altar, and fog
-- together instead of independently rolling mismatched alternatives.
local function church_theme(api)
    if api:coinflip() then
        api:emit(directives.KMONS, "3 = kobold brigand / quasit")
        api:emit(directives.KMONS, "4 = kobold brigand")
        api:emit(directives.KMONS, "5 = quasit")
        api:emit(directives.KFEAT, "B = altar_makhleb")
        api:emit(directives.MARKER,
            'F = lua:fog_machine { cloud_type = "flame", ' ..
            'pow_min = 100, pow_max = 100, delay = 10, size = 1, ' ..
            'walk_dist = 0, excl_rad = 0 }')

        return
    end

    api:emit(directives.KMONS, "34 = kobold brigand / wight")
    api:emit(directives.KMONS, "5 = phantom / necrophage")
    api:emit(directives.KFEAT, "B = altar_kikubaaqudgha")
    api:emit(directives.SUBST, "F : VY")
end

shared.setup = setup
shared.loot_mixed = loot_mixed
shared.loot_potions = loot_potions
shared.loot_scrolls = loot_scrolls
shared.loot_sparse = loot_sparse
shared.loot_armour = loot_armour
shared.loot_aux_armour = loot_aux_armour
shared.question_potions = question_potions
shared.bang_scrolls = bang_scrolls
shared.e_potions = e_potions
shared.f_scrolls = f_scrolls
shared.clear_stone_window = clear_stone_window
shared.church_theme = church_theme

return shared
