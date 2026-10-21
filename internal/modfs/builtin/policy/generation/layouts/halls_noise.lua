-- Theory of operation: preserve pinned perlin.cc simplex permutations and
-- worley.cc Poisson feature counts, uint32 LCG, and density adjustment. Field
-- constructors draw source offsets once; all later 3D samples are pure. The
-- source Worley license is retained with its lookup data in halls_noise_tables.
local tables = require("policy.generation.layouts.halls_noise_tables")

local noise = {}
local uint32 = 4294967296
local density = 0.398150

local gradients = {
    {
        1,
        1,
        0,
    },
    {
        -1,
        1,
        0,
    },
    {
        1,
        -1,
        0,
    },
    {
        -1,
        -1,
        0,
    },
    {
        1,
        0,
        1,
    },
    {
        -1,
        0,
        1,
    },
    {
        1,
        0,
        -1,
    },
    {
        -1,
        0,
        -1,
    },
    {
        0,
        1,
        1,
    },
    {
        0,
        -1,
        1,
    },
    {
        0,
        1,
        -1,
    },
    {
        0,
        -1,
        -1,
    },
}

-- The source permutation repeats every 256 entries at each nesting level.
local function permutation(index)
    return tables.permutation[index % 256 + 1]
end

-- Choose the exact pinned simplex gradient at one tetrahedron corner.
local function contribution(i, j, k, x, y, z)
    local radius = 0.6 - x * x - y * y - z * z

    if radius <= 0 then
        return 0
    end

    local gradient = gradients[permutation(i + permutation(j + permutation(k))) % 12 + 1]
    local dot = gradient[1] * x + gradient[2] * y + gradient[3] * z

    radius = radius * radius

    return radius * radius * dot
end

-- Order the second and third simplex corners by their coordinate ranks.
-- This gives the broad continuous shapes of source procedural.simplex3d.
local function simplex_corners(x, y, z)
    if x >= y then
        if y >= z then
            return 1, 0, 0, 1, 1, 0
        elseif x >= z then
            return 1, 0, 0, 1, 0, 1
        end

        return 0, 0, 1, 1, 0, 1
    end

    if y < z then
        return 0, 0, 1, 0, 1, 1
    elseif x < z then
        return 0, 1, 0, 0, 1, 1
    end

    return 0, 1, 0, 1, 1, 0
end

-- Evaluate four gradient contributions in skewed 3D simplex space.
local function simplex3(x, y, z)
    local skew = (x + y + z) * (1 / 3)
    local i = math.floor(x + skew)
    local j = math.floor(y + skew)
    local k = math.floor(z + skew)
    local unskew = (i + j + k) * (1 / 6)
    local x0 = x - (i - unskew)
    local y0 = y - (j - unskew)
    local z0 = z - (k - unskew)
    local i1, j1, k1, i2, j2, k2 = simplex_corners(x0, y0, z0)
    local first = contribution(i, j, k, x0, y0, z0)
    local second = contribution(i + i1, j + j1, k + k1, x0 - i1 + 1 / 6, y0 - j1 + 1 / 6, z0 - k1 + 1 / 6)
    local third = contribution(i + i2, j + j2, k + k2, x0 - i2 + 1 / 3, y0 - j2 + 1 / 3, z0 - k2 + 1 / 3)
    local fourth = contribution(i + 1, j + 1, k + 1, x0 - 1 + 0.5, y0 - 1 + 0.5, z0 - 1 + 0.5)

    return 32 * (first + second + third + fourth)
end

-- Construct one source-style simplex field. Three fractional offsets
-- ensure even a flat z slice varies from floor to floor.
function noise.simplex(builder, scale, unit)
    local field = {
        scale = scale / 10,
        x = 100 + builder:roll(1000000) / 1000000,
        y = 100 + builder:roll(1000000) / 1000000,
        z = 100 + builder:roll(1000000) / 1000000,
        unit = unit,
    }

    return field
end

-- Sample the fixed field without drawing further randomness. Unit mode
-- mirrors the source's conversion from signed simplex to the 0..1 range.
function noise.simplex_at(field, x, y)
    local value = simplex3(x * field.scale + field.x, y * field.scale + field.y, field.z)

    if field.unit then
        return value / 2 + 0.5
    end

    return value
end

-- Multiply uint32 values exactly using sixteen-bit limbs. A direct Lua
-- double product loses the low bits of the source Worley LCG state.
local function multiply32(first, second)
    local first_low = first % 65536
    local second_low = second % 65536
    local first_high = math.floor(first / 65536)
    local second_high = math.floor(second / 65536)
    local cross = (first_low * second_high + first_high * second_low) % 65536

    return (first_low * second_low + cross * 65536) % uint32
end

-- Advance the source maximal-period Worley feature-point generator.
local function churn(seed)
    return (multiply32(1402024253, seed) + 586950981) % uint32
end

-- Cache every source feature in a lattice cube. Its count is Poisson-like,
-- so a single fixed feature per cube would produce different corridor widths.
local function features(field, x, y, z)
    local key = x .. ":" .. y .. ":" .. z
    local cached = field.cache[key]

    if cached then
        return cached
    end

    local seed = (702395077 * x + 915488749 * y + 2120969693 * z) % uint32
    local count = tables.poisson[math.floor(seed / 16777216) + 1]
    local points = {}

    seed = churn(seed)

    for _ = 1, count do
        seed = churn(seed)

        local feature_x = (seed + 0.5) / uint32

        seed = churn(seed)

        local feature_y = (seed + 0.5) / uint32

        seed = churn(seed)

        local feature_z = (seed + 0.5) / uint32

        seed = churn(seed)
        points[#points + 1] = {
            x = x + feature_x,
            y = y + feature_y,
            z = z + feature_z,
        }
    end

    field.cache[key] = points

    return points
end

-- The pinned LFLOOR macro chooses the preceding cube for negative integers.
local function lattice_floor(value)
    if value < 0 then
        return math.ceil(value) - 1
    end

    return math.floor(value)
end

-- Sample the same 27 source cubes. Exhaustive sampling is equivalent to
-- the source's distance-pruned traversal for its two nearest feature points.
function noise.worley_at(field, x, y, z)
    local px = (x * field.scale + field.x) * density
    local py = (y * field.scale + field.y) * density
    local pz = ((z or 0) * field.scale + field.z) * density
    local x_cell = lattice_floor(px)
    local y_cell = lattice_floor(py)
    local z_cell = lattice_floor(pz)
    local closest = math.huge
    local second = math.huge

    for near_z = z_cell - 1, z_cell + 1 do
        for near_y = y_cell - 1, y_cell + 1 do
            for near_x = x_cell - 1, x_cell + 1 do
                for _, point in ipairs(features(field, near_x, near_y, near_z)) do
                    local dx = point.x - px
                    local dy = point.y - py
                    local dz = point.z - pz
                    local distance = dx * dx + dy * dy + dz * dz

                    if distance < closest then
                        second = closest
                        closest = distance
                    elseif distance < second then
                        second = distance
                    end
                end
            end
        end
    end

    return math.sqrt(second) * (1 / density) - math.sqrt(closest) * (1 / density)
end

-- Source offsets and their three bounded draws are fixed before sampling.
function noise.worley(builder, scale)
    return {
        scale = scale * 0.8,
        x = builder:roll(1000000),
        y = builder:roll(1000000),
        z = builder:roll(1000000),
        cache = {},
    }
end

return noise
