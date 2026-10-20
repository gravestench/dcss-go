-- Theory of operation: Gehenna has three source canyon backbones. Basic
-- crosses the level with optional wide ends, Box chooses one or two sides
-- on each axis, and Triple joins three long bands at one or both ends.
-- All three roughen the floor, may author up stairs, then run the same
-- Gehenna pool and building epilogue before the shared stair postpass.
local grid = require("policy.generation.grid")
local shared = require("policy.generation.layouts.gehenna_shared")
local spotty = require("policy.generation.layouts.spotty")
local cleanup = require("policy.generation.layouts.cave_cleanup")
local subdivision = require("policy.generation.layouts.subdivision")
local glyphs = require("constants.vault_glyphs")

local layout = {}

local center_y = grid.height / 2
local left_x = shared.edge
local left_inner_x = shared.edge + shared.stair_spacing_x
local right_x = grid.width - shared.edge
local right_inner_x = right_x - shared.stair_spacing_x
local small_upper_y = center_y - shared.stair_spacing_y
local small_lower_y = center_y + shared.stair_spacing_y

-- Basic can have a broad vertical end or a slim one on either side.
-- Those booleans also determine which authored stair sites are available.
local function basic_ends(builder)
    local wide_left = builder:one_in(3)
    local wide_right = builder:one_in(3)
    local iterations = 4

    if wide_left then
        shared.fill(builder,
            left_x - shared.basic_path, shared.edge,
            left_x + shared.basic_path, grid.height - shared.edge, ".")
        iterations = iterations + 0.5
    else
        shared.fill(builder, left_inner_x, small_upper_y,
            left_inner_x, small_lower_y, ".")
    end

    shared.fill(builder, left_x, center_y - shared.basic_path,
        right_x, center_y + shared.basic_path, ".")

    if wide_right then
        shared.fill(builder,
            right_x - shared.basic_path, shared.edge,
            right_x + shared.basic_path, grid.height - shared.edge, ".")
        iterations = iterations + 0.5
    else
        shared.fill(builder, right_inner_x, small_upper_y,
            right_inner_x, small_lower_y, ".")
    end

    return wide_left, wide_right, iterations
end

-- One-third of basic canyons contain a central diamond, sometimes with
-- an inner rock diamond that turns it into a ring around the main path.
local function basic_middle(builder, iterations)
    if not builder:one_in(3) then
        return iterations
    end

    local x = grid.width / 2 + subdivision.range(builder, -2, 2)
    local y = center_y + subdivision.range(builder, -2, 2)
    local radius = subdivision.range(builder,
        grid.height / 2 - 10, grid.height / 2 - 4)

    shared.diamond(builder, x, y, radius, ".")

    if builder:one_in(2) then
        shared.diamond(builder, x, y,
            radius - shared.basic_path * 2, "#")
    end

    return iterations + 1
end

-- The six endpoint candidates reproduce source big-end and small-end
-- coordinates; only three may survive the source stair shuffle.
local function basic_stair_sites(wide_left, wide_right)
    local positions = {
        { x = left_x, y = center_y },
        { x = right_x, y = center_y },
    }

    if wide_left then
        positions[#positions + 1] = { x = left_x, y = shared.edge }
        positions[#positions + 1] = {
            x = left_x,
            y = grid.height - shared.edge,
        }
    else
        positions[#positions + 1] = {
            x = left_inner_x,
            y = small_upper_y,
        }
        positions[#positions + 1] = {
            x = left_inner_x,
            y = small_lower_y,
        }
    end

    if wide_right then
        positions[#positions + 1] = { x = right_x, y = shared.edge }
        positions[#positions + 1] = {
            x = right_x,
            y = grid.height - shared.edge,
        }
    else
        positions[#positions + 1] = {
            x = right_inner_x,
            y = small_upper_y,
        }
        positions[#positions + 1] = {
            x = right_inner_x,
            y = small_lower_y,
        }
    end

    return positions
end

-- Two independent eight-way draws produce the source's box/U/L shape
-- distribution: both sides are rarer than either single side.
local function box_sides(builder)
    local horizontal = builder:roll(8)
    local vertical = builder:roll(8)
    local upper_y = center_y - 15
    local lower_y = center_y + 15
    local iterations = 4

    if horizontal < 5 then
        shared.fill(builder, left_x,
            upper_y - shared.basic_path,
            right_x, upper_y + shared.basic_path, ".")
        iterations = iterations + 1
    end

    if horizontal >= 3 then
        shared.fill(builder, left_x,
            lower_y - shared.basic_path,
            right_x, lower_y + shared.basic_path, ".")
        iterations = iterations + 1
    end

    if vertical < 5 then
        shared.fill(builder,
            left_x - shared.basic_path, upper_y,
            left_x + shared.basic_path, lower_y, ".")
        iterations = iterations + 0.5
    end

    if vertical >= 3 then
        shared.fill(builder,
            right_x - shared.basic_path, upper_y,
            right_x + shared.basic_path, lower_y, ".")
        iterations = iterations + 0.5
    end

    return iterations
end

-- The source Triple layout has three bands twenty cells apart at this
-- builder size; narrow paths at an end can merge into the central band.
local function triple_bands(builder, x1, x2)
    local spacing = grid.height * 2 / 7

    for _, y in ipairs({ center_y - spacing, center_y, center_y + spacing }) do
        shared.fill(builder, x1, y - shared.triple_path,
            x2, y + shared.triple_path, ".")
    end
end

-- Return the source end style and last division. A middle style makes
-- separate upper and lower crossbars, each with its own random x position.
local function triple_shape(builder)
    local division_min = left_inner_x + 15
    local division_max = right_inner_x - 15
    local division = subdivision.range(builder,
        division_min, division_max)
    local open_end = builder:roll(7)
    local spacing = grid.height * 2 / 7
    local upper_y = center_y - spacing
    local lower_y = center_y + spacing
    local iterations

    if open_end < 2 then
        shared.fill(builder, left_inner_x, small_upper_y,
            left_inner_x, small_lower_y, ".")
        shared.fill(builder, left_x, center_y - shared.basic_path,
            division, center_y + shared.basic_path, ".")
    else
        triple_bands(builder, left_x, division)
    end

    if open_end < 2 or open_end >= 5 then
        shared.fill(builder,
            division - shared.triple_path, upper_y,
            division + shared.triple_path, lower_y, ".")
        iterations = 5.5
    else
        shared.fill(builder,
            division - shared.triple_path, upper_y,
            division + shared.triple_path, center_y, ".")
        division = subdivision.range(builder,
            division_min, division_max)
        shared.fill(builder,
            division - shared.triple_path, center_y,
            division + shared.triple_path, lower_y, ".")
        iterations = 6
    end

    if open_end >= 5 then
        shared.fill(builder, right_inner_x, small_upper_y,
            right_inner_x, small_lower_y, ".")
        shared.fill(builder, division, center_y - shared.basic_path,
            right_x, center_y + shared.basic_path, ".")
    else
        triple_bands(builder, division, right_x)
    end

    return open_end, iterations
end

-- Triple's small end places both side stairs on its inner x column;
-- otherwise they use the outer x column and the three path heights.
local function triple_stair_sites(open_end)
    local spacing = grid.height * 2 / 7
    local upper_y = center_y - spacing
    local lower_y = center_y + spacing
    local left_side = open_end < 2 and left_inner_x or left_x
    local right_side = open_end >= 5 and right_inner_x or right_x
    local left_upper = open_end < 2 and small_upper_y or upper_y
    local left_lower = open_end < 2 and small_lower_y or lower_y
    local right_upper = open_end >= 5 and small_upper_y or upper_y
    local right_lower = open_end >= 5 and small_lower_y or lower_y

    return {
        { x = left_x, y = center_y },
        { x = left_side, y = left_upper },
        { x = left_side, y = left_lower },
        { x = right_x, y = center_y },
        { x = right_side, y = right_upper },
        { x = right_side, y = right_lower },
    }
end

-- Roughening precedes the source epilogue so pools grow on the final cave
-- floor rather than on the straight bands used to seed it.
local function finish(builder, api, iterations, stair_sites)
    spotty.carve(builder, false, math.floor(iterations * 100))
    cleanup.remove_isolated(builder, "#", 100, false)

    local authored_up_count = 0

    if stair_sites then
        authored_up_count = shared.authored_up(builder, stair_sites)
    end

    local pool_count, room_count = shared.epilogue(builder, api)

    if builder.bad_random then
        error("Gehenna pools could not obtain a bounded random draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
        pool_count = pool_count,
        room_count = room_count,
        authored_up_count = authored_up_count,
    }
end

-- Source OPEN_CAVES requires more than fifteen percent ordinary floor
-- or authored stairs before the shared layout stair postpass runs.
function layout.validate(result)
    local open = 0
    local builder = result.builder

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            local glyph = builder:cell(x, y)

            if glyph == "." or glyphs.up[glyph] or glyphs.down[glyph] then
                open = open + 1
            end
        end
    end

    return open > grid.width * grid.height * 0.15
end

-- Basic uses one long horizontal canyon and independently sized ends.
function layout.basic(api)
    local builder = grid.new(api.ctx)
    local wide_left, wide_right, iterations = basic_ends(builder)

    iterations = basic_middle(builder, iterations)

    return finish(builder, api, iterations,
        basic_stair_sites(wide_left, wide_right))
end

-- Box deliberately leaves one or two sides on each axis and relies on
-- the cave growth pass to turn its rectilinear outline into rough terrain.
function layout.box(api)
    local builder = grid.new(api.ctx)
    local iterations = box_sides(builder)

    return finish(builder, api, iterations)
end

-- Triple may join all three paths at one end, both ends, or separate
-- crossbars. Its source stairs are sampled before lava pools expand.
function layout.triple(api)
    local builder = grid.new(api.ctx)
    local open_end, iterations = triple_shape(builder)

    return finish(builder, api, iterations,
        triple_stair_sites(open_end))
end

return layout
