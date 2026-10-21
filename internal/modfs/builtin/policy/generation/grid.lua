-- Example: A fresh grid starts with rock at its perimeter before room carving.
local grid = {}
grid.__index = grid

local dimensions = require("constants.level_dimensions")
local default_width = dimensions.FULL_WIDTH
local default_height = dimensions.FULL_HEIGHT
local uint32 = 4294967296

grid.width = default_width
grid.height = default_height

-- Allocate one level's dense matrix. Ordinary levels retain the source
-- 80x70 extent; non-bottom Hell floors pass their source 40x35 extent.
-- Dimensions belong to this builder, never to mutable module globals, so
-- nested map choices cannot change another floor's geometry.
function grid.new(ctx, requested_width, requested_height)
    local width = requested_width or default_width
    local height = requested_height or default_height
    local cells = {}

    if width < 3 or height < 3 or width % 1 ~= 0 or height % 1 ~= 0 then
        error("invalid generation grid dimensions")
    end

    for y = 1, height do
        cells[y] = {}

        for x = 1, width do
            cells[y][x] = "#"
        end
    end

    return setmetatable({
        ctx = ctx,
        cells = cells,
        width = width,
        height = height,
        bad_random = false,
    }, grid)
end

-- Translate zero-based world coordinates to Lua table indices for terrain reads.
function grid:cell(x, y)
    return self.cells[y + 1][x + 1]
end

-- Write one zero-based terrain cell through the same indexing convention as reads.
function grid:set(x, y, glyph)
    self.cells[y + 1][x + 1] = glyph
end

-- Keep trail endpoints off the immutable outer wall.
function grid:inside(point)
    return point.x > 0 and point.x < self.width - 1 and
        point.y > 0 and point.y < self.height - 1
end

-- Translate the Go builder's bounded uint64 draw without modulo bias before layout choices consume it.
function grid:roll(n)
    if n <= 1 or self.bad_random then
        return 0
    end

    -- Go's uint64 threshold is (-bound) % bound, equal to 2^64 % bound.
    local factor = uint32 % n
    local threshold = (factor * factor) % n

    for _ = 1, 16 do
        local hi, lo = self.ctx:random_u64("layout")

        if hi > 0 or lo >= threshold then
            return ((hi % n) * factor + (lo % n)) % n
        end
    end

    self.bad_random = true
    return 0
end

-- Use the builder roll so one-in-N decisions share its unbiased bounded draw.
function grid:one_in(n)
    return self:roll(n) == 0
end

-- Avoid an RNG draw for impossible or certain corridor probabilities.
function grid:chance_in(chance, total)
    if chance <= 0 then
        return false
    end

    if chance >= total then
        return true
    end

    return self:roll(total) < chance
end

-- Freeze mutable cell arrays as strings for level serialization.
function grid:rows()
    local rows = {}

    for y = 1, self.height do
        rows[y] = table.concat(self.cells[y])
    end

    return rows
end

return grid
