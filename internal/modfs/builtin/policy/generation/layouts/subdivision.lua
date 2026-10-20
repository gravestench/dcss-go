-- Theory of operation: source omnigrid recursively divides a rectangular
-- floor into cells. The Hyper painter first lays floor across that rectangle,
-- then leaves selected cell interiors as unpainted rock. The strips between
-- interiors become a connected grid of corridors. This module ports those
-- two steps directly for layouts that do not use omnigrid's tile/group API.
local grid = require("policy.generation.grid")

local subdivision = {}

-- Source random_range is inclusive; placing it here keeps bounds and jitter
-- draws consistent across the two grid layouts.
local function range(builder, first, last)
    return first + builder:roll(last - first + 1)
end

-- Choose a source-sized Hyper room inside the level's immutable rock rim.
-- A varied position lets extra vaults occupy other parts of the level.
local function room_bounds(builder)
    local width = range(builder, grid.width - 22, grid.width - 2)
    local height = range(builder, grid.height - 22, grid.height - 2)
    local x1 = range(builder, 1, grid.width - width - 1)
    local y1 = range(builder, 1, grid.height - height - 1)

    return {
        x1 = x1,
        y1 = y1,
        x2 = x1 + width - 1,
        y2 = y1 + height - 1,
        width = width,
        height = height,
    }
end

-- Subdivide one local rectangle. Guaranteed levels precede the falling
-- chance; an axis that is too short forces the other axis if possible.
local function split(builder, area, options, chance, depth, cells)
    local width = area.x2 - area.x1 + 1
    local height = area.y2 - area.y1 + 1
    local can_x = width >= 2 * options.minimum_size_x
    local can_y = height >= 2 * options.minimum_size_y
    local guaranteed = depth < options.guaranteed_divides

    if not can_x and not can_y then
        cells[#cells + 1] = area
        return
    end

    if not guaranteed and builder:roll(100) >= chance then
        cells[#cells + 1] = area
        return
    end

    local axis

    if not can_x then
        axis = "y"
    elseif not can_y then
        axis = "x"
    elseif options.axis then
        axis = options.axis
    else
        axis = builder:roll(2) == 0 and "x" or "y"
    end

    -- The source long-grid callback keeps requesting one axis; once that
    -- axis reaches its minimum, continue on the other available axis.
    if axis == "x" and not can_x then
        axis = "y"
    elseif axis == "y" and not can_y then
        axis = "x"
    end

    local next_chance = chance * options.multiplier

    if axis == "x" then
        local cut = range(builder, options.minimum_size_x, width - options.minimum_size_x)
        local left = {
            x1 = area.x1,
            y1 = area.y1,
            x2 = area.x1 + cut - 1,
            y2 = area.y2,
        }
        local right = {
            x1 = area.x1 + cut,
            y1 = area.y1,
            x2 = area.x2,
            y2 = area.y2,
        }

        split(builder, left, options, next_chance, depth + 1, cells)
        split(builder, right, options, next_chance, depth + 1, cells)
    else
        local cut = range(builder, options.minimum_size_y, height - options.minimum_size_y)
        local upper = {
            x1 = area.x1,
            y1 = area.y1,
            x2 = area.x2,
            y2 = area.y1 + cut - 1,
        }
        local lower = {
            x1 = area.x1,
            y1 = area.y1 + cut,
            x2 = area.x2,
            y2 = area.y2,
        }

        split(builder, upper, options, next_chance, depth + 1, cells)
        split(builder, lower, options, next_chance, depth + 1, cells)
    end
end

-- Compute the unpainted cell interior from source corridor width and edge
-- rules. Jitter changes each side independently before clipping to the room.
local function interior(builder, cell, bounds, paint)
    local half_low = math.floor(paint.corridor_width / 2)
    local half_high = math.ceil(paint.corridor_width / 2)
    local left = cell.x1 + half_low
    local top = cell.y1 + half_low
    local right = cell.x2 - half_high
    local bottom = cell.y2 - half_high

    -- An outer cell keeps its edge when the exterior corridor is off. The
    -- source starts the rock interior at the edge in that case.
    if cell.x1 == 0 then
        left = cell.x1 + (paint.outer_corridor and paint.corridor_width or 0)
    end

    if cell.y1 == 0 then
        top = cell.y1 + (paint.outer_corridor and paint.corridor_width or 0)
    end

    if cell.x2 == bounds.width - 1 then
        right = cell.x2 - (paint.outer_corridor and paint.corridor_width or 0)
    end

    if cell.y2 == bounds.height - 1 then
        bottom = cell.y2 - (paint.outer_corridor and paint.corridor_width or 0)
    end

    if paint.jitter then
        left = left - range(builder, paint.jitter_min, paint.jitter_max)
        top = top - range(builder, paint.jitter_min, paint.jitter_max)
        right = right + range(builder, paint.jitter_min, paint.jitter_max)
        bottom = bottom + range(builder, paint.jitter_min, paint.jitter_max)
    end

    return {
        x1 = math.max(0, left),
        y1 = math.max(0, top),
        x2 = math.min(bounds.width - 1, right),
        y2 = math.min(bounds.height - 1, bottom),
    }
end

-- Paint one cell's source "space" area as the rock already underneath the
-- floor pass. A failed jittered rectangle leaves its cell as open floor.
local function leave_rock(builder, bounds, inside)
    if inside.x1 > inside.x2 or inside.y1 > inside.y2 then
        return
    end

    for y = inside.y1, inside.y2 do
        for x = inside.x1, inside.x2 do
            builder:set(bounds.x1 + x, bounds.y1 + y, "#")
        end
    end
end

-- Paint the single Hyper floor and its unpainted subdivided interiors.
-- The returned cell list remains useful to layout-specific tests and future
-- overlays without adding a second copy of the room geometry.
function subdivision.render(builder, options, paint)
    local bounds = room_bounds(builder)
    local cells = {}
    local local_bounds = {
        x1 = 0,
        y1 = 0,
        x2 = bounds.width - 1,
        y2 = bounds.height - 1,
    }

    split(builder, local_bounds, options, options.initial_chance, 0, cells)

    for y = bounds.y1, bounds.y2 do
        for x = bounds.x1, bounds.x2 do
            builder:set(x, y, ".")
        end
    end

    for _, cell in ipairs(cells) do
        if builder:roll(100) < paint.fill_chance then
            leave_rock(builder, bounds, interior(builder, cell, bounds, paint))
        end
    end

    return cells
end

-- Omnigrid city and maze layouts subdivide most of the builder rather than
-- placing one Hyper room. Their four padding draws stay source-local here.
function subdivision.partition(builder, options, minimum_pad, maximum_pad)
    local bounds = {
        x1 = 1 + range(builder, minimum_pad, maximum_pad),
        y1 = 1 + range(builder, minimum_pad, maximum_pad),
        x2 = grid.width - 2 - range(builder, minimum_pad, maximum_pad),
        y2 = grid.height - 2 - range(builder, minimum_pad, maximum_pad),
    }
    local cells = {}

    split(builder, bounds, options, options.initial_chance, 0, cells)

    return cells, bounds
end

-- Source random_range_real uses a real-valued uniform draw. A million
-- fixed steps are sufficient for its subdivision chance multipliers.
function subdivision.real(builder, first, last)
    return first + (last - first) * builder:roll(1000000) / 1000000
end

subdivision.range = range

return subdivision
