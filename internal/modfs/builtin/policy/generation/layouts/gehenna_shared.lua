-- Theory of operation: all three Gehenna pool layouts draw a narrow canyon,
-- roughen it with spotty growth, and then run this shared source epilogue.
-- The epilogue grows lava and cover pools, adds occasional stone buildings,
-- and fills disconnected floor and lava zones before stair completion.
local grid = require("policy.generation.grid")
local spotty = require("policy.generation.layouts.spotty")
local cleanup = require("policy.generation.layouts.cave_cleanup")
local pools = require("policy.generation.layouts.pools")
local regions = require("policy.generation.layouts.cell_graph")
local subdivision = require("policy.generation.layouts.subdivision")

local shared = {}

shared.edge = 15
shared.stair_spacing_x = 3
shared.stair_spacing_y = 8
shared.basic_path = 2
shared.triple_path = 1

local floor_passable = {
    ["."] = true,
    ["+"] = true,
    ["{"] = true,
    ["("] = true,
    ["["] = true,
    ["}"] = true,
    [")"] = true,
    ["]"] = true,
}

local lava_passable = {
    ["."] = true,
    ["+"] = true,
    l = true,
    ["{"] = true,
    ["("] = true,
    ["["] = true,
    ["}"] = true,
    [")"] = true,
    ["]"] = true,
}

-- Clip the source inclusive fill_area rectangle to the playable builder.
-- All source canyons start as rock and add floor through these bands.
function shared.fill(builder, x1, y1, x2, y2, glyph)
    for y = math.max(1, math.floor(y1)),
        math.min(builder.height - 2, math.floor(y2)) do
        for x = math.max(1, math.floor(x1)),
            math.min(builder.width - 2, math.floor(x2)) do
            builder:set(x, y, glyph)
        end
    end
end

-- Source make_diamond measures the taxicab radius around the center.
-- Its optional inner rock diamond can turn a broad middle into a ring.
function shared.diamond(builder, center_x, center_y, radius, glyph)
    for y = math.max(1, center_y - radius),
        math.min(builder.height - 2, center_y + radius) do
        for x = math.max(1, center_x - radius),
            math.min(builder.width - 2, center_x + radius) do
            if math.abs(x - center_x) + math.abs(y - center_y) <= radius then
                builder:set(x, y, glyph)
            end
        end
    end
end

-- A fifth of source canyons deliberately place up stairs at one or both
-- ends. The source shuffles six temporary glyphs and removes down glyphs;
-- choosing three endpoint cells has the same retained-stair effect.
function shared.authored_up(builder, positions)
    if not builder:chance_in(20, 100) then
        return 0
    end

    local glyphs = { "{", "(", "[" }

    for _, glyph in ipairs(glyphs) do
        local index = builder:roll(#positions) + 1
        local point = table.remove(positions, index)

        builder:set(point.x, point.y, glyph)
    end

    return #glyphs
end

-- Source depth_fraction spans zero at Geh:1 to one at Geh:7 and controls
-- both pool size and the number and size of later stone buildings.
local function depth_fraction(api)
    return (api.depth - 1) / math.max(1, api.branch_bottom - 1)
end

-- Count rock and metal cover in one proposed building footprint. A room
-- needs at least half cover but cannot sit entirely inside existing wall.
local function cover_count(builder, x1, y1, x2, y2)
    local count = 0

    for y = y1, y2 do
        for x = x1, x2 do
            local glyph = builder:cell(x, y)

            if glyph == "#" or glyph == "v" then
                count = count + 1
            end
        end
    end

    return count
end

-- Source find_in_area vetoes overlap with a prior stone building and
-- requires a separating margin so their round walls remain readable.
local function nearby_building(builder, x1, y1, x2, y2, separation)
    for y = math.max(1, y1 - separation),
        math.min(builder.height - 2, y2 + separation) do
        for x = math.max(1, x1 - separation),
            math.min(builder.width - 2, x2 + separation) do
            if builder:cell(x, y) == "c" then
                return true
            end
        end
    end

    return false
end

-- Construct the source rounded room off-map first. Its ellipse cells that
-- touch outside remain stone; the rest become floor. Only straight wall
-- runs next to existing traversable terrain may receive a door.
local function rounded_room(builder, x1, y1, size)
    local cells = {}
    local radius = size / 2

    for y = 0, size do
        cells[y] = {}

        for x = 0, size do
            local dx = (x - radius) / (radius + 0.5)
            local dy = (y - radius) / (radius + 0.5)

            cells[y][x] = dx * dx + dy * dy <= 1 and "c" or nil
        end
    end

    for y = 1, size - 1 do
        for x = 1, size - 1 do
            if cells[y][x] and cells[y - 1][x - 1] and
                cells[y - 1][x] and cells[y - 1][x + 1] and
                cells[y][x - 1] and cells[y][x + 1] and
                cells[y + 1][x - 1] and cells[y + 1][x] and
                cells[y + 1][x + 1] then
                cells[y][x] = "."
            end
        end
    end

    local doors = {}

    -- Temporary ellipse coordinates include the extreme edge. Most long
    -- straight walls lie there, so excluding it would veto every building.
    local function cell(x, y)
        return cells[y] and cells[y][x]
    end

    for y = 0, size do
        for x = 0, size do
            if cell(x, y) == "c" then
                local horizontal = cell(x - 1, y) == "c" and
                    cell(x + 1, y) == "c" and
                    cell(x, y - 1) ~= "c" and
                    cell(x, y + 1) ~= "c"
                local vertical = cell(x, y - 1) == "c" and
                    cell(x, y + 1) == "c" and
                    cell(x - 1, y) ~= "c" and
                    cell(x + 1, y) ~= "c"
                local outside = horizontal and
                    (not cell(x, y - 1) and
                        builder:cell(x1 + x, y1 + y - 1) == "." or
                        not cell(x, y + 1) and
                        builder:cell(x1 + x, y1 + y + 1) == ".") or
                    vertical and
                    (not cell(x - 1, y) and
                        builder:cell(x1 + x - 1, y1 + y) == "." or
                        not cell(x + 1, y) and
                        builder:cell(x1 + x + 1, y1 + y) == ".")

                if outside then
                    doors[#doors + 1] = { x = x, y = y }
                end
            end
        end
    end

    if #doors == 0 then
        return false
    end

    local count = subdivision.range(builder, 1, 3)

    for _ = 1, math.min(count, #doors) do
        local index = builder:roll(#doors) + 1
        local point = table.remove(doors, index)

        cells[point.y][point.x] = "+"
    end

    for y = 0, size do
        for x = 0, size do
            if cells[y][x] then
                builder:set(x1 + x, y1 + y, cells[y][x])
            end
        end
    end

    return true
end

-- The source samples more buildings deeper in Gehenna. A candidate is
-- accepted only when its cover ratio and stone separation allow a door.
function shared.add_buildings(builder, api)
    local fraction = depth_fraction(api)
    local border = 4
    local maximum_size = math.floor(6 + 4 * fraction)
    local separation = subdivision.range(builder, 1,
        math.floor(border - fraction * 2))
    local minimum_count = math.floor((150 + fraction * 850) / maximum_size)
    local maximum_count = math.floor((300 + fraction * 1700) / maximum_size)
    local accepted = 0

    for _ = 1, subdivision.range(builder, minimum_count, maximum_count) do
        local size = subdivision.range(builder, 4, maximum_size)
        local x1 = subdivision.range(builder, border,
            builder.width - 1 - border - size)
        local y1 = subdivision.range(builder, border,
            builder.height - 1 - border - size)
        local x2 = x1 + size
        local y2 = y1 + size
        local cover = cover_count(builder, x1, y1, x2, y2)

        if cover >= size * size * 0.5 and cover < size * size and
            not nearby_building(builder, x1, y1, x2, y2, separation) and
            rounded_room(builder, x1, y1, size) then
            accepted = accepted + 1
        end
    end

    return accepted
end

-- Preserve the source pass order: cover and lava pools grow before new
-- rooms; metal becomes rock; floor-only zones are filled before the pass
-- that permits lava to connect what remains.
function shared.epilogue(builder, api)
    local fraction = depth_fraction(api)
    local bottom = api.branch_bottom

    cleanup.widen_paths(builder, "#", 10)

    local pool_count = pools.add(builder,
        math.floor(40 + 40 * fraction), {
            { glyph = "v", weight = bottom * 2 - api.depth },
            { glyph = "l", weight = bottom * 2 },
            { glyph = ".", weight = bottom },
        })
    local room_count = shared.add_buildings(builder, api)

    cleanup.widen_paths(builder, "v", 90)

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            if builder:cell(x, y) == "v" then
                builder:set(x, y, "#")
            end
        end
    end

    cleanup.remove_isolated(builder, "#", 75, false)
    cleanup.widen_paths(builder, "l", 60)
    cleanup.remove_isolated(builder, "l", 90, true)
    regions.keep_largest_region(builder, floor_passable)
    regions.keep_largest_region(builder, lava_passable)

    return pool_count, room_count
end

return shared
