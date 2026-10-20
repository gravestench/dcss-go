-- Theory of operation: source column_ruins.des calls three shared Lua
-- helpers at authored positions. The DES files retain all geometry and
-- local substitutions. This module builds their common ruined pillars,
-- hut surfaces, portal style, and the few branch-dependent variants.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")
local setup = {}

-- Probabilistic source glyphs use the layout stream in their directive
-- order. Keep the final underscore-to-floor step after the tile and colour
-- records so a ruined column's presentation survives substitution.
local function configure(api)
    api:emit(directives.SUBST, "J = _____.")
    api:emit(directives.SUBST, "K = ____..")
    api:emit(directives.SUBST, "L = ___...")
    api:emit(directives.SUBST, "M = __....")
    api:emit(directives.SUBST, "N = _.....")
    api:emit(directives.SUBST, "p = GGGG_")
    api:emit(directives.SUBST, "q = GGG__")
    api:emit(directives.SUBST, "r = GG__.")
    api:emit(directives.SUBST, "s = G_...")
    api:emit(directives.FTILE, "_$%*90GTUVB = floor_rough_brown")
    api:emit(directives.COLOUR, "_$%*90V = brown")
    api:emit(directives.TILE, "G = dngn_crumbled_column")
    api:emit(directives.COLOUR, "G = lightgrey")
    api:emit(directives.SUBST, "_ = .")
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.BROKEN_PILLAR,
    })
    api:emit(directives.KFEAT, "B = altar_ecumenical")
end

-- Hut walls and doorways use the old city wall tile and forbid the normal
-- wall fixup from changing their authored shape.
local function hut(api)
    api:emit(directives.FTILE, "x = floor_rough_brown")
    api:emit(directives.RTILE, "x = wall_catacombs")
    api:emit(directives.KMASK, "x = no_wall_fixup")
    api:emit(directives.FTILE, "+ = floor_rough_brown")
    api:emit(directives.RTILE, "+ = wall_catacombs")
    api:emit(directives.KMASK, "+ = no_wall_fixup")
end

-- The same portal shape can become an Abyss, Hell, or Pandemonium entry.
-- The source draws for Abyss first, then conditionally draws for Hell.
local function portal(api)
    local feature
    local floor

    api:emit(directives.SUBST, "? = ???-")

    if api:one_in(3) then
        feature = "enter_abyss"
        floor = "floor_nerves"
    elseif api:one_in(2) then
        feature = "enter_hell"
        floor = "floor_infernal"
    else
        feature = "enter_pandemonium"
        floor = "floor_demonic"
    end

    api:emit(directives.KFEAT, "O = " .. feature)
    api:emit(directives.KFEAT, "P = " .. feature)
    api:emit(directives.FTILE, "- = " .. floor)
    api:emit(directives.FTILE, "? = " .. floor)
    api:emit(directives.FTILE, "O = " .. floor)
    api:emit(directives.FTILE, "P = floor_rough_brown")
    api:emit(directives.TILE, "? = dngn_crumbled_column")
    api:emit(directives.KPROP, "- = no_tele_into")
    api:emit(directives.KPROP, "? = no_tele_into")
    api:emit(directives.KPROP, "O = no_tele_into")
    api:emit(directives.SUBST, "- = .")
end

-- A half-chance outer moat turns the square portal's floor and pillars
-- into a lava-ring arrangement before the shared portal rules run.
local function portal_squares(api)
    if api:one_in(2) then
        api:emit(directives.SUBST, "JKL : l")
        api:emit(directives.SUBST, "p = ?")
        api:emit(directives.SUBST, "_ : -")
        api:emit(directives.SUBST, "P : O")
    end
end

-- The astroid's optional source variation thickens its portal columns.
local function portal_astroid(api)
    if api:one_in(3) then
        api:emit(directives.SUBST, "l : _")
        api:emit(directives.SUBST, "O : P")
        api:emit(directives.SUBST, "p : ppT")
        api:emit(directives.SUBST, "T = TTUVVV")
    end
end

-- The long watery courtyard keeps some water while introducing lava only
-- when the current branch is Depths.
local function water_mix(api)
    if api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.SUBST, "w : wl")
    end
end

-- The other watery shapes convert eligible pools to lava in Depths, as
-- their source conditional directives do before the common pillar setup.
local function water_lava(api)
    if api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.SUBST, "w : l")
    end
end

setup.configure = configure
setup.hut = hut
setup.portal = portal
setup.portal_squares = portal_squares
setup.portal_astroid = portal_astroid
setup.water_mix = water_mix
setup.water_lava = water_lava

return setup
