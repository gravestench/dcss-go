-- Theory of operation: cave layouts sample smooth simplex fields for broad
-- shapes and cellular distance fields for angular ridges. A constructor
-- consumes the layout RNG once for offsets; sampling coordinates afterward
-- is pure, so map traversal order cannot change a generated cave.
local grid = require("policy.generation.grid")

local noise = {}

local uint32 = 4294967296

local gradients = {
    { 1, 1, 0 },
    { -1, 1, 0 },
    { 1, -1, 0 },
    { -1, -1, 0 },
    { 1, 0, 1 },
    { -1, 0, 1 },
    { 1, 0, -1 },
    { -1, 0, -1 },
    { 0, 1, 1 },
    { 0, -1, 1 },
    { 0, 1, -1 },
    { 0, -1, -1 },
}

-- Clamp source border and noise mappings to a probability-like range.
local function clamp(value)
    return math.max(0, math.min(1, value))
end

-- Hash lattice coordinates without mutable global state. The source uses
-- fixed gradient and cellular hashes; this keeps the same mathematical
-- fields while allowing the layout stream to choose their offsets.
local function hash(x, y, z, salt)
    local value = (x * 73856093 + y * 19349663 +
        z * 83492791 + salt * 2654435761) % uint32

    return (value * 1664525 + 1013904223) % uint32
end

-- Choose the source simplex gradient at one tetrahedron corner.
local function contribution(i, j, k, x, y, z)
    local radius = 0.6 - x * x - y * y - z * z

    if radius <= 0 then
        return 0
    end

    local gradient = gradients[hash(i, j, k, 0) % #gradients + 1]
    local dot = gradient[1] * x + gradient[2] * y + gradient[3] * z

    return radius * radius * radius * radius * dot
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
    local skew = (x + y + z) / 3
    local i = math.floor(x + skew)
    local j = math.floor(y + skew)
    local k = math.floor(z + skew)
    local unskew = (i + j + k) / 6
    local x0 = x - i + unskew
    local y0 = y - j + unskew
    local z0 = z - k + unskew
    local i1, j1, k1, i2, j2, k2 = simplex_corners(x0, y0, z0)
    local first = contribution(i, j, k, x0, y0, z0)
    local second = contribution(i + i1, j + j1, k + k1,
        x0 - i1 + 1 / 6, y0 - j1 + 1 / 6, z0 - k1 + 1 / 6)
    local third = contribution(i + i2, j + j2, k + k2,
        x0 - i2 + 1 / 3, y0 - j2 + 1 / 3, z0 - k2 + 1 / 3)
    local fourth = contribution(i + 1, j + 1, k + 1,
        x0 - 0.5, y0 - 0.5, z0 - 0.5)

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
    local value = simplex3(x * field.scale + field.x,
        y * field.scale + field.y, field.z)

    if field.unit then
        return value / 2 + 0.5
    end

    return value
end

-- Source Worley noise places a point in each nearby lattice cell and
-- compares the closest two distances. Cache those stable points because
-- adjacent map cells ask about the same small lattice neighborhood.
local function feature(field, x, y, z)
    local key = x .. ":" .. y .. ":" .. z
    local point = field.cache[key]

    if point then
        return point
    end

    point = {
        x = x + hash(x, y, z, 1) / uint32,
        y = y + hash(x, y, z, 2) / uint32,
        z = z + hash(x, y, z, 3) / uint32,
    }
    field.cache[key] = point

    return point
end

-- Draw three large offsets just as procedural.worley_diff does before
-- returning its pure sampling function.
function noise.worley(builder, scale)
    return {
        scale = scale * 0.8,
        x = builder:roll(1000000),
        y = builder:roll(1000000),
        z = builder:roll(1000000),
        cache = {},
    }
end

-- Compare the nearest two 3D feature points around a sampled map cell.
-- Their difference is low on cell borders and high near a feature center.
function noise.worley_at(field, x, y)
    local px = x * field.scale + field.x
    local py = y * field.scale + field.y
    local pz = field.z
    local x_cell = math.floor(px)
    local y_cell = math.floor(py)
    local z_cell = math.floor(pz)
    local closest = math.huge
    local second = math.huge

    for near_z = z_cell - 1, z_cell + 1 do
        for near_y = y_cell - 1, y_cell + 1 do
            for near_x = x_cell - 1, x_cell + 1 do
                local point = feature(field, near_x, near_y, near_z)
                local dx = px - point.x
                local dy = py - point.y
                local dz = pz - point.z
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

    return math.sqrt(second) - math.sqrt(closest)
end

-- Source border fields fade inward over padding + 1 cells. Additive mode
-- weighs x and y borders independently for Cave Pods' corner suppression.
function noise.border(x, y, padding, additive)
    local near_x = math.min(x, grid.width - 1 - x)
    local near_y = math.min(y, grid.height - 1 - y)

    if additive then
        return math.min(1, 2 - clamp(near_x / (padding + 1)) -
            clamp(near_y / (padding + 1)))
    end

    return 1 - clamp(math.min(near_x, near_y) / (padding + 1))
end

-- The central-cavern variant scales Euclidean distance by its radius.
function noise.distance(x, y, center_x, center_y, radius)
    local dx = x - center_x
    local dy = y - center_y

    return math.sqrt(dx * dx + dy * dy) / radius
end

-- The source procedural boundary map fades from zero to one and back.
-- Cocytus uses it independently on both axes to keep water off the rim.
function noise.boundary(value, first, full_start, full_end, last)
    if value <= first or value >= last then
        return 0
    elseif value >= full_start and value <= full_end then
        return 1
    elseif value < full_start then
        return (value - first) / (full_start - first)
    end

    return (last - value) / (last - full_end)
end

-- Snake and Spider bend both pod fields with two independent simplex
-- offsets. The original transform scales those offsets toward map center.
function noise.damped_distortion(builder)
    local x_scale = 0.1 + builder:roll(900001) / 1000000
    local x_field = noise.simplex(builder, x_scale, false)
    local y_scale = 0.1 + builder:roll(900001) / 1000000
    local y_field = noise.simplex(builder, y_scale, false)

    return {
        x = x_field,
        y = y_field,
        scale = 4 + builder:roll(5),
    }
end

-- Sample a cellular field after applying the source damped domain offset.
-- A nil transform leaves Dungeon and Lair fields at their original points.
function noise.distorted_worley_at(field, distortion, x, y)
    if not distortion then
        return noise.worley_at(field, x, y)
    end

    local near = math.min(x, y, grid.width - 1 - x, grid.height - 1 - y)
    local half = math.min((grid.width - 1) / 2, (grid.height - 1) / 2)
    local damping = math.max(0, near / half)
    local offset_x = noise.simplex_at(distortion.x, x, y) * damping
    local offset_y = noise.simplex_at(distortion.y, x, y) * damping

    return noise.worley_at(field,
        x + offset_x * distortion.scale,
        y + offset_y * distortion.scale)
end

return noise
