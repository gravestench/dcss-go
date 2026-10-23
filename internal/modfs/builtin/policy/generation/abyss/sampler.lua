-- Source _abyss_grid composes small layout families rather than choosing
-- a terrain feature directly. Keep that composition in Lua so mods can
-- replace one texture without changing the engine's numeric kernel.
local constants = require("constants.abyss")
local borrowed = require("policy.generation.abyss.borrowed")
local chaos = require("policy.generation.abyss.roiling_chaos")
local features = require("policy.generation.abyss.features")
local rivers = require("policy.generation.abyss.rivers")
local wastes = require("policy.generation.abyss.wastes")
local worley = require("policy.generation.abyss.worley")

local sampler = {}

-- These four shapes are stable across morph depth and give the regular
-- Worley regions their recognizable columns and diamonds.
local function diamond_wide(ctx, _, x, y, depth)
    return features.diamond(ctx, x, y, depth, 3, 0)
end

-- This narrower, separated diamond is the second source variant.
local function diamond_spaced(ctx, _, x, y, depth)
    return features.diamond(ctx, x, y, depth, 2, 1)
end

-- A width-two column has equal spacing between rock columns.
local function column_equal(ctx, _, x, y, depth)
    return features.column(ctx, x, y, depth, 2, 2)
end

-- A width-two column with six-cell spacing makes the sparse variant.
local function column_sparse(ctx, _, x, y, depth)
    return features.column(ctx, x, y, depth, 2, 6)
end

local regular_layouts = {
    diamond_wide,
    diamond_spaced,
    column_equal,
    column_sparse,
}

-- The source's default Worley scale is two for its regular blend.
local function regular(ctx, state, x, y, depth)
    return worley.mix(ctx, state, x, y, depth,
        constants.REGULAR_WORLEY_SEED, 2, regular_layouts)
end

-- Each roiling variant retains its own fixed seed and density, so
-- shifting the blend never makes all four patches look alike.
local function roiling_a(ctx, _, x, y, depth)
    return chaos.roiling(ctx, x, y, depth,
        constants.ROILING_SEED_A, 450)
end

-- The second source patch is slightly less dense than the first.
local function roiling_b(ctx, _, x, y, depth)
    return chaos.roiling(ctx, x, y, depth,
        constants.ROILING_SEED_B, 400)
end

-- The third source patch is the most open of the four.
local function roiling_c(ctx, _, x, y, depth)
    return chaos.roiling(ctx, x, y, depth,
        constants.ROILING_SEED_C, 380)
end

-- The fourth source patch reaches the densest wall threshold.
local function roiling_d(ctx, _, x, y, depth)
    return chaos.roiling(ctx, x, y, depth,
        constants.ROILING_SEED_D, 500)
end

-- The newer banded layout is also a child of the mixed texture.
local function new_abyss(ctx, _, x, y, depth)
    return chaos.new_abyss(ctx, x, y, depth)
end

local mixed_layouts = {
    roiling_a,
    regular,
    roiling_b,
    roiling_c,
    roiling_d,
    new_abyss,
}

-- The first blend chooses among the six visibly different textures.
local function mixed(ctx, state, x, y, depth)
    return worley.mix(ctx, state, x, y, depth,
        constants.MIXED_WORLEY_SEED, 2, mixed_layouts)
end

local base_layouts = {
    new_abyss,
    mixed,
}

-- The broader five-cell blend prevents one texture from filling a
-- whole region and is the dry fallback around river channels.
local function base(ctx, state, x, y, depth)
    return worley.mix(ctx, state, x, y, depth,
        constants.BASE_WORLEY_SEED,
        constants.WORLEY_BASE_SCALE, base_layouts)
end

-- Rivers overlay thin water seams onto the already composed base.
local function river(ctx, state, x, y, depth)
    return rivers.sample(ctx, state, x, y, depth, base)
end

-- Borrowed ordinary terrain is the first outer-region child. Its
-- eroded cells delegate to rivers and then to the base blend.
local function source_floor(ctx, state, x, y, depth)
    return borrowed.sample(ctx, state, x, y, depth, river)
end

local complex_layouts = {
    source_floor,
    river,
}

-- The source's outermost Worley alternates borrowed and generated
-- terrain, making existing floors recognizable without copying exits.
local function complex(ctx, state, x, y, depth)
    return worley.mix(ctx, state, x, y, depth,
        constants.COMPLEX_WORLEY_SEED,
        constants.WORLEY_COMPLEX_SCALE, complex_layouts)
end

-- Sample one local cell in the moving 80x70 window. The sample also
-- returns the morph depth at which that cell may next change.
function sampler.sample(ctx, state, x, y)
    local world_x = features.signed32(state.world_x + x)
    local world_y = features.signed32(state.world_y + y)
    local depth = state.morph_depth
    local inside_wastes = world_x > 0 and
        world_x < constants.WASTES_LIMIT and
        world_y > 0 and world_y < constants.WASTES_LIMIT

    if inside_wastes then
        return wastes.sample(ctx, world_x, world_y, depth)
    end

    return complex(ctx, state, world_x, world_y, depth)
end

return sampler
