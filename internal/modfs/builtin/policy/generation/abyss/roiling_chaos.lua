-- The source mixes four moving Chaos regions with a newer wall pattern.
-- None of these modules choose where they are used; sampler.lua composes
-- them, keeping each source density rule small enough to read.
local constants = require("constants.abyss")
local features = require("policy.generation.abyss.features")
local terrain = require("constants.terrain")
local worley = require("policy.generation.abyss.worley")

local chaos = {}

-- Density is changed by bits of the region seed before the per-cell hash
-- is compared with 1000. The source's wall palette remains weighted.
function chaos.sample(ctx, x, y, depth, seed, base_density)
    local density = base_density + seed % 50 +
        math.floor(seed / 65536) % 60
    local roll = ctx:hash3_quotient_mod(x, y, seed, 1, 1000)

    if roll < density then
        local wall = features.pseudorandom_wall(ctx, x, y, seed, 3)

        return wall, depth + constants.STATIC_CHANGE
    end

    return terrain.DNGN_FLOOR, depth + constants.STATIC_CHANGE
end

-- A moving Voronoi point supplies the Chaos seed. Its distance gap
-- schedules the next refresh before the closest point changes.
function chaos.roiling(ctx, x, y, depth, seed, density)
    local scale = density - 350 + 4800
    local cellular = ctx:worley(x, y, depth / scale)
    local region_seed = (cellular.id[1] + seed) % 4294967296
    local feature, static_change = chaos.sample(ctx,
        x, y, depth, region_seed, density)
    local change = worley.change_point(cellular, scale, depth)

    return feature, math.min(static_change, change)
end

-- New Abyss walls depend on both a fine Voronoi distance band and one
-- exact 64-bit coordinate hash. The occasional inverted band breaks
-- what would otherwise be a predictable ring texture.
function chaos.new_abyss(ctx, x, y, depth)
    local cellular = ctx:worley(x / 3.2, y / 3.2, depth / 1000)
    local distance = math.floor(cellular.distance[1] * 100)
    local wall = distance > 118 or distance < 30
    local delta = math.min(math.abs(distance - 118),
        math.abs(30 - distance))
    local seed = constants.NEW_ABYSS_SEED

    if (cellular.id[1] + cellular.id[2]) % 6 == 0 then
        wall = false
    end

    if ctx:hash3_quotient_mod(x, y, seed, 1, 3) == 0 then
        wall = not wall
    end

    if wall then
        local fuzz = 0

        if ctx:hash3_quotient_mod(x, y, seed, 3, 3) == 0 then
            fuzz = ctx:hash3_quotient_mod(x, y, seed, 9, 3) - 1
        end

        local slot = (cellular.id[1] + fuzz) % 9
        -- Pseudorandom wall uses a hash; NewAbyss instead indexes the
        -- same nine-slot palette directly with its cellular point ID.
        local wall_type = features.wall_at_slot(slot)

        return wall_type, depth + delta
    end

    return terrain.DNGN_FLOOR, depth + delta
end

return chaos
