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

-- Each canyon computes its own reference points from its builder size.
-- Keeping these local to the build also lets the same module generate the
-- source compact Hell floors and full-sized layouts in one session.
local function geometry(builder)
    local center_y = math.floor(builder.height / 2)
    local right_x = builder.width - shared.edge

    return {
        center_y = center_y,
        left_x = shared.edge,
        left_inner_x = shared.edge + shared.stair_spacing_x,
        right_x = right_x,
        right_inner_x = right_x - shared.stair_spacing_x,
        small_upper_y = center_y - shared.stair_spacing_y,
        small_lower_y = center_y + shared.stair_spacing_y,
        height = builder.height,
    }
end

-- Basic can have a broad vertical end or a slim one on either side.
-- Those booleans also determine which authored stair sites are available.
local function basic_ends(builder, site)
    local wide_left = builder:one_in(3)
    local wide_right = builder:one_in(3)
    local iterations = 4

    if wide_left then
        shared.fill(builder,
            site.left_x - shared.basic_path, shared.edge,
            site.left_x + shared.basic_path, builder.height - shared.edge, ".")
        iterations = iterations + 0.5
    else
        shared.fill(builder, site.left_inner_x, site.small_upper_y,
            site.left_inner_x, site.small_lower_y, ".")
    end

    shared.fill(builder, site.left_x, site.center_y - shared.basic_path,
        site.right_x, site.center_y + shared.basic_path, ".")

    if wide_right then
        shared.fill(builder,
            site.right_x - shared.basic_path, shared.edge,
            site.right_x + shared.basic_path, builder.height - shared.edge, ".")
        iterations = iterations + 0.5
    else
        shared.fill(builder, site.right_inner_x, site.small_upper_y,
            site.right_inner_x, site.small_lower_y, ".")
    end

    return wide_left, wide_right, iterations
end

-- One-third of basic canyons contain a central diamond, sometimes with
-- an inner rock diamond that turns it into a ring around the main path.
local function basic_middle(builder, site, iterations)
    if not builder:one_in(3) then
        return iterations
    end

    local x = builder.width / 2 + subdivision.range(builder, -2, 2)
    local y = site.center_y + subdivision.range(builder, -2, 2)
    local radius = subdivision.range(builder,
        builder.height / 2 - 10, builder.height / 2 - 4)

    shared.diamond(builder, x, y, radius, ".")

    if builder:one_in(2) then
        shared.diamond(builder, x, y,
            radius - shared.basic_path * 2, "#")
    end

    return iterations + 1
end

-- The six endpoint candidates reproduce source big-end and small-end
-- coordinates; only three may survive the source stair shuffle.
local function basic_stair_sites(site, wide_left, wide_right)
    local positions = {
        { x = site.left_x, y = site.center_y },
        { x = site.right_x, y = site.center_y },
    }

    if wide_left then
        positions[#positions + 1] = { x = site.left_x, y = shared.edge }
        positions[#positions + 1] = {
            x = site.left_x,
            y = site.height - shared.edge,
        }
    else
        positions[#positions + 1] = {
            x = site.left_inner_x,
            y = site.small_upper_y,
        }
        positions[#positions + 1] = {
            x = site.left_inner_x,
            y = site.small_lower_y,
        }
    end

    if wide_right then
        positions[#positions + 1] = { x = site.right_x, y = shared.edge }
        positions[#positions + 1] = {
            x = site.right_x,
            y = site.height - shared.edge,
        }
    else
        positions[#positions + 1] = {
            x = site.right_inner_x,
            y = site.small_upper_y,
        }
        positions[#positions + 1] = {
            x = site.right_inner_x,
            y = site.small_lower_y,
        }
    end

    return positions
end

-- Two independent eight-way draws produce the source's box/U/L shape
-- distribution: both sides are rarer than either single side.
local function box_sides(builder, site)
    local horizontal = builder:roll(8)
    local vertical = builder:roll(8)
    local upper_y = site.center_y - 15
    local lower_y = site.center_y + 15
    local iterations = 4

    if horizontal < 5 then
        shared.fill(builder, site.left_x,
            upper_y - shared.basic_path,
            site.right_x, upper_y + shared.basic_path, ".")
        iterations = iterations + 1
    end

    if horizontal >= 3 then
        shared.fill(builder, site.left_x,
            lower_y - shared.basic_path,
            site.right_x, lower_y + shared.basic_path, ".")
        iterations = iterations + 1
    end

    if vertical < 5 then
        shared.fill(builder,
            site.left_x - shared.basic_path, upper_y,
            site.left_x + shared.basic_path, lower_y, ".")
        iterations = iterations + 0.5
    end

    if vertical >= 3 then
        shared.fill(builder,
            site.right_x - shared.basic_path, upper_y,
            site.right_x + shared.basic_path, lower_y, ".")
        iterations = iterations + 0.5
    end

    return iterations
end

-- The source Triple layout has three bands twenty cells apart at this
-- builder size; narrow paths at an end can merge into the central band.
local function triple_bands(builder, site, x1, x2)
    local spacing = builder.height * 2 / 7

    local bands = {
        site.center_y - spacing,
        site.center_y,
        site.center_y + spacing,
    }

    for _, y in ipairs(bands) do
        shared.fill(builder, x1, y - shared.triple_path,
            x2, y + shared.triple_path, ".")
    end
end

-- Return the source end style and last division. A middle style makes
-- separate upper and lower crossbars, each with its own random x position.
local function triple_shape(builder, site)
    local division_min = site.left_inner_x + 15
    local division_max = site.right_inner_x - 15
    local division = subdivision.range(builder,
        division_min, division_max)
    local open_end = builder:roll(7)
    local spacing = builder.height * 2 / 7
    local upper_y = site.center_y - spacing
    local lower_y = site.center_y + spacing
    local iterations

    if open_end < 2 then
        shared.fill(builder, site.left_inner_x, site.small_upper_y,
            site.left_inner_x, site.small_lower_y, ".")
        shared.fill(builder, site.left_x, site.center_y - shared.basic_path,
            division, site.center_y + shared.basic_path, ".")
    else
        triple_bands(builder, site, site.left_x, division)
    end

    if open_end < 2 or open_end >= 5 then
        shared.fill(builder,
            division - shared.triple_path, upper_y,
            division + shared.triple_path, lower_y, ".")
        iterations = 5.5
    else
        shared.fill(builder,
            division - shared.triple_path, upper_y,
            division + shared.triple_path, site.center_y, ".")
        division = subdivision.range(builder,
            division_min, division_max)
        shared.fill(builder,
            division - shared.triple_path, site.center_y,
            division + shared.triple_path, lower_y, ".")
        iterations = 6
    end

    if open_end >= 5 then
        shared.fill(builder, site.right_inner_x, site.small_upper_y,
            site.right_inner_x, site.small_lower_y, ".")
        shared.fill(builder, division, site.center_y - shared.basic_path,
            site.right_x, site.center_y + shared.basic_path, ".")
    else
        triple_bands(builder, site, division, site.right_x)
    end

    return open_end, iterations
end

-- Triple's small end places both side stairs on its inner x column;
-- otherwise they use the outer x column and the three path heights.
local function triple_stair_sites(builder, site, open_end)
    local spacing = builder.height * 2 / 7
    local upper_y = site.center_y - spacing
    local lower_y = site.center_y + spacing
    local left_side = open_end < 2 and site.left_inner_x or site.left_x
    local right_side = open_end >= 5 and site.right_inner_x or site.right_x
    local left_upper = open_end < 2 and site.small_upper_y or upper_y
    local left_lower = open_end < 2 and site.small_lower_y or lower_y
    local right_upper = open_end >= 5 and site.small_upper_y or upper_y
    local right_lower = open_end >= 5 and site.small_lower_y or lower_y

    return {
        { x = site.left_x, y = site.center_y },
        { x = left_side, y = left_upper },
        { x = left_side, y = left_lower },
        { x = site.right_x, y = site.center_y },
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

    for y = 0, builder.height - 1 do
        for x = 0, builder.width - 1 do
            local glyph = builder:cell(x, y)

            if glyph == "." or glyphs.up[glyph] or glyphs.down[glyph] then
                open = open + 1
            end
        end
    end

    return open > builder.width * builder.height * 0.15
end

-- Basic uses one long horizontal canyon and independently sized ends.
function layout.basic(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local site = geometry(builder)
    local wide_left, wide_right, iterations = basic_ends(builder, site)

    iterations = basic_middle(builder, site, iterations)

    return finish(builder, api, iterations,
        basic_stair_sites(site, wide_left, wide_right))
end

-- Box deliberately leaves one or two sides on each axis and relies on
-- the cave growth pass to turn its rectilinear outline into rough terrain.
function layout.box(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local iterations = box_sides(builder, geometry(builder))

    return finish(builder, api, iterations)
end

-- Triple may join all three paths at one end, both ends, or separate
-- crossbars. Its source stairs are sampled before lava pools expand.
function layout.triple(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local site = geometry(builder)
    local open_end, iterations = triple_shape(builder, site)

    return finish(builder, api, iterations,
        triple_stair_sites(builder, site, open_end))
end

return layout
